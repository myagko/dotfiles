local utf8 = require("lua-utf8")
local Gio = require("lgi").require("Gio")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gfs = require("gears.filesystem")
local common = require("common")
local user = require("user")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi
local lua_escape = require("lib").lua_escape
local is_supported = require("lib").is_supported
local table_to_file = require("lib").table_to_file
local capi = { screen = screen }
local powermenu = require("ui.powermenu").get_default()

local launcher = {}

local function launch_app(app)
	if not app then return end
	local desktop_app_info = Gio.DesktopAppInfo.new(Gio.AppInfo.get_id(app))
	local term_needed = Gio.DesktopAppInfo.get_string(desktop_app_info, "Terminal") == "true" and true or false
	local term = Gio.AppInfo.get_default_for_uri_scheme('terminal')

	awful.spawn(
		term_needed and
			term and string.format("%s -e %s", term:get_executable(), app:get_executable())
		or
			string.match(app:get_executable(), "^env") and
				string.gsub(app:get_commandline(), "%%%a", "")
			or
				app:get_executable()
	)
end

local function filter_apps(apps, query)
	query = lua_escape(query)
	local filtered = {}
	local filtered_any = {}

	for _, app in ipairs(apps) do
		if app:should_show() then
			local name_match = utf8.lower(utf8.sub(app:get_name(), 1, utf8.len(query))) == utf8.lower(query)
			local name_match_any = utf8.match(utf8.lower(app:get_name()), utf8.lower(query))
			local exec_match_any = utf8.match(utf8.lower(app:get_executable()), utf8.lower(query))

			if name_match then
				table.insert(filtered, app)
			elseif name_match_any or exec_match_any then
				table.insert(filtered_any, app)
			end
		end
	end

	table.sort(filtered, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	table.sort(filtered_any, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	for i = 1, #filtered_any do
		filtered[#filtered + 1] = filtered_any[i]
	end

	return filtered
end

function launcher:next()
	if #self.filtered > 1 and self.index_entry ~= #self.filtered then
		self.index_entry = self.index_entry + 1
		if self.index_entry > self.index_start + self.rows - 1 then
			self.index_start = self.index_start + 1
		end
	else
		self.index_entry = 1
		self.index_start = 1
	end
end

function launcher:back()
	if #self.filtered > 1 and self.index_entry ~= 1 then
		self.index_entry = self.index_entry - 1
		if self.index_entry < self.index_start then
			self.index_start = self.index_start - 1
		end
	else
		self.index_entry = #self.filtered
		if #self.filtered < self.rows then
			self.index_start = 1
		else
			self.index_start = #self.filtered - self.rows + 1
		end
	end
end

function launcher:update_entries()
	local entries_container = self.main_widget:get_children_by_id("entries_container")[1]
	entries_container:reset()

	if #self.filtered > 0 then
		for i, app in ipairs(self.filtered) do
			if i >= self.index_start and i <= self.index_start + self.rows - 1 then
				local entry_widget = wibox.widget {
					widget = wibox.container.background,
					forced_height = dpi(55),
					shape = beautiful.rrect(dpi(10)),
					{
						widget = wibox.container.margin,
						margins = dpi(15),
						{
							widget = wibox.widget.textbox,
							markup = app:get_name()
						}
					}
				}

				entry_widget:buttons {
					awful.button({}, 1, function()
						if self.index_entry == i then
							launch_app(app)
							self:hide()
						else
							self.index_entry = i
							self:update_entries()
						end
					end)
				}

				if i == self.index_entry then
					entry_widget:set_bg(beautiful.ac)
					entry_widget:set_fg(beautiful.bg)
				else
					entry_widget:connect_signal("mouse::enter", function(w)
						w:set_bg(beautiful.bg_urg)
					end)

					entry_widget:connect_signal("mouse::leave", function(w)
						w:set_bg(beautiful.bg)
					end)
				end

				entries_container:add(entry_widget)
			end
		end
	else
		local empty_massage = wibox.widget {
			widget = wibox.container.background,
			forced_height = dpi(200),
			fg = beautiful.fg_alt,
			{
				widget = wibox.widget.textbox,
				font = beautiful.font_h2,
				align = "center",
				markup = "No match found"
			}
		}
		entries_container:add(empty_massage)
	end
end

function launcher:show()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:emit_signal("state", self.state)
	self.unfiltered = Gio.AppInfo.get_all()
	self.filtered = filter_apps(self.unfiltered, "")
	self.index_start, self.index_entry = 1, 1
	self:update_entries()
	self.text_input:run_keygrabber()
end

function launcher:hide()
	if not self.state then return end
	self.state = false
	self.unfiltered = {}
	self.filtered = {}
	self.index_entry, self.index_entry = 1, 1
	self.text_input:stop_keygrabber()
	self.popup_widget.visible = false
	self:emit_signal("state", self.state)
end

function launcher:toggle()
	if not self.popup_widget.visible then
		self:show()
	else
		self:hide()
	end
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, launcher, true)

	ret.rows = 6

	local input_textbox = wibox.widget {
		widget = wibox.widget.textbox,
		ellipsize = "start",
	}

	ret.text_input = common.text_input {
		textbox = input_textbox,
		placeholder = "Search...",
		cursor_bg = beautiful.fg,
		cursor_fg = beautiful.bg,
		placeholder_fg = beautiful.fg_alt,
		done_callback = function()
			ret:hide()
		end,
		changed_callback = function(input)
			ret.filtered = filter_apps(ret.unfiltered, input)
			ret.index_start, ret.index_entry = 1, 1
			ret:update_entries()
		end,
		exe_callback = function()
			local app = ret.filtered[ret.index_entry]
			if app then
				launch_app(app)
			end
		end,
		keypressed_callback = function(_, key)
			if key == "Down" then
				ret:next()
				ret:update_entries()
			elseif key == "Up" then
				ret:back()
				ret:update_entries()
			end
		end
	}

	local sidebar_home_button = common.hover_button {
		markup = text_icons.home,
		forced_width = dpi(55),
		forced_height = dpi(55),
		shape = beautiful.rrect(dpi(10)),
		buttons = {
			awful.button({}, 1, function()
				awful.spawn("xdg-open " .. os.getenv("HOME"))
				ret:hide()
			end)
		}
	}

	local sidebar_wallpapers_button = common.hover_button {
		markup = text_icons.image,
		forced_width = dpi(55),
		forced_height = dpi(55),
		shape = beautiful.rrect(dpi(10)),
		buttons = {
			awful.button({}, 1, function()
				awful.spawn.easy_async("zenity --file-selection", function(stdout)
					stdout = string.gsub(stdout, "\n", "")
					local formats = { "png", "jpg", "jpeg" }
					if stdout ~= nil and stdout ~= "" and is_supported(stdout, formats) then
						for s in capi.screen do
							s.wallpaper:set_image(stdout)
						end
						user.wallpaper = stdout
						table_to_file(user, gfs.get_configuration_dir() .. "/user.lua")
					end
				end)
				ret:hide()
			end)
		}
	}

	local sidebar_poweroff_button = common.hover_button {
		markup = text_icons.poweroff,
		forced_width = dpi(55),
		forced_height = dpi(55),
		fg_normal = beautiful.red,
		bg_hover = beautiful.red,
		shape = beautiful.rrect(dpi(10)),
		buttons = {
			awful.button({}, 1, function()
				powermenu:show()
			end)
		}
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(10),
		{
			widget = wibox.container.background,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(6),
				fill_space = true,
				{
					widget = wibox.container.background,
					forced_width = dpi(55),
					bg = beautiful.bg_alt,
					shape = beautiful.rrect(dpi(10)),
					{
						layout = wibox.layout.align.vertical,
						sidebar_poweroff_button,
						nil,
						{
							layout = wibox.layout.fixed.vertical,
							spacing = beautiful.separator_thickness + dpi(2),
							spacing_widget = {
								widget = wibox.container.margin,
								margins = { left = dpi(12), right = dpi(12) },
								{
									widget = wibox.widget.separator,
									orientation = "horizontal"
								}
							},
							sidebar_wallpapers_button,
							sidebar_home_button,
						}
					}
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(3),
					{
						widget = wibox.container.margin,
						forced_width = 1,
						forced_height = dpi(55),
						margins = dpi(10),
						{
							widget = wibox.container.constraint,
							strategy = "max",
							height = dpi(25),
							input_textbox
						}
					},
					{
						widget = wibox.container.background,
						forced_width = 1,
						forced_height = beautiful.separator_thickness,
						{
							widget = wibox.widget.separator,
							orientation = "horizontal"
						}
					},
					{
						id = "entries_container",
						layout = wibox.layout.fixed.vertical,
						spacing = dpi(3),
						forced_width = dpi(290),
						forced_height = dpi(55)*ret.rows + dpi(3)*(ret.rows - 1),
						buttons = {
							awful.button({}, 4, function()
								ret:back()
								ret:update_entries()
							end),
							awful.button({}, 5, function()
								ret:next()
								ret:update_entries()
							end)
						}
					}
				}
			}
		}
	}

	ret.popup_widget = awful.popup {
		ontop = true,
		visible = false,
		screen = capi.screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color_normal,
		--shape = beautiful.rrect(dpi(20)),
		placement = function(d)
			awful.placement.bottom_left(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end,
		widget = ret.main_widget
	}

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return {
	get_default = get_default
}
