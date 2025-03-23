local utf8 = require("lua-utf8")
local Gio = require("lgi").Gio
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local common = require("common")
local user = require("user")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi
local lua_escape = require("helpers").lua_escape
local capi = { screen = screen }

local powermenu = require("ui.powermenu")

local launcher = {}
local instance = nil

local rows = 6

local terminal_cmds = {
	alacritty = "alacritty -e ",
	termite = "termite -e ",
	rxvt = "rxvt -e ",
	terminator = "terminator -e "
}

local function launch_app(app)
	local terminal_cmd = user.terminal and terminal_cmds[user.terminal] or nil
	local desktop_app_info = Gio.DesktopAppInfo.new(Gio.AppInfo.get_id(app))
	local terminal = Gio.DesktopAppInfo.get_string(desktop_app_info, "Terminal") == "true" and true or false
	if terminal and terminal_cmd then
		awful.spawn(terminal_cmd .. app:get_executable())
	else
		app:launch()
	end
end

function launcher:next()
	if #self.filtered > 1 and self.index_entry ~= #self.filtered then
		self.index_entry = self.index_entry + 1
		if self.index_entry > self.index_start + rows - 1 then
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
		if #self.filtered < rows then
			self.index_start = 1
		else
			self.index_start = #self.filtered - rows + 1
		end
	end
end

function launcher:filter()
	self.filtered = {}
	local filtered_any = {}
	local esc_input = lua_escape(self.text_input:get_input())

	for _, app in ipairs(self.unfiltered) do
		if app:should_show() then
			local name_match = utf8.lower(utf8.sub(app:get_name(), 1, utf8.len(esc_input))) == utf8.lower(esc_input)
			local name_match_any = utf8.match(utf8.lower(app:get_name()), utf8.lower(esc_input))
			local exec_match_any = utf8.match(string.lower(app:get_executable()), utf8.lower(esc_input))

			if name_match then
				table.insert(self.filtered, app)
			elseif name_match_any or exec_match_any then
				table.insert(filtered_any, app)
			end
		end
	end

	table.sort(self.filtered, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)
	table.sort(filtered_any, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	for i = 1, #filtered_any do
		self.filtered[#self.filtered + 1] = filtered_any[i]
	end

	self.index_start, self.index_entry = 1, 1
end

function launcher:update_entries()
	local entries_container = self.main_widget:get_children_by_id("entries_container")[1]
	entries_container:reset()

	for i, app in ipairs(self.filtered) do
		if i >= self.index_start and i <= self.index_start + rows - 1 then
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
						self:close()
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
end

function launcher:open()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:emit_signal("state", self.state)
	self.unfiltered = Gio.AppInfo.get_all()
	self:filter()
	self:update_entries()
	self.text_input:run_keygrabber()
end

function launcher:close()
	if not self.state then return end
	self.state = false
	self.text_input:stop_keygrabber()
	self.popup_widget.visible = false
	self:emit_signal("state", self.state)
end

function launcher:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, launcher, true)

	local input_textbox = wibox.widget {
		widget = wibox.widget.textbox
	}

	ret.text_input = common.text_input {
		textbox = input_textbox,
		prompt = text_icons.search .. " ",
		placeholder = "Search...",
		cursor_bg = beautiful.fg,
		cursor_fg = beautiful.bg,
		placeholder_fg = beautiful.fg_alt,
		done_callback = function()
			ret:close()
		end,
		changed_callback = function()
			ret:filter()
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
				ret:close()
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
				if user.wallpapers_folder then
					awful.spawn("xdg-open " .. user.wallpapers_folder)
					ret:close()
				end
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
				powermenu:open()
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
							spacing = beautiful.sep_width,
							spacing_widget = common.separator {
								vertical = true,
								margins = { left = dpi(12), right = dpi(12) }
							},
							sidebar_wallpapers_button,
							sidebar_home_button,
						}
					}
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(6),
					{
						widget = wibox.container.background,
						bg = beautiful.border_color,
						forced_height = dpi(55),
						forced_width = dpi(55),
						{
							widget = wibox.container.margin,
							margins = { bottom = beautiful.sep_width },
							{
								widget = wibox.container.background,
								bg = beautiful.bg,
								{
									widget = wibox.container.margin,
									margins = { left = dpi(10), right = dpi(10) },
									input_textbox
								}
							}
						}
					},
					{
						id = "entries_container",
						layout = wibox.layout.fixed.vertical,
						spacing = dpi(3),
						forced_width = dpi(290),
						forced_height = dpi(55)*rows + dpi(3)*(rows - 1),
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
		border_color = beautiful.border_color,
		shape = beautiful.rrect(dpi(20)),
		placement = function(d)
			awful.placement.bottom_left(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap*2
			})
		end,
		widget = ret.main_widget
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
