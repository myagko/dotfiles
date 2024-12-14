local utf8 = require("lua-utf8")
local Gio = require("lgi").Gio
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local widgets = require("widgets")
local helpers = require("helpers")
local user = require("user")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local powermenu = require("ui.powermenu")
local control = require("ui.control_panel")

local terminals_map = {
	alacritty = "alacritty -e",
	termite = "termite -e",
	rxvt = "rxvt -e",
	terminator = "terminator -e"
}

local terminal_command = user.terminal and terminals_map[user.terminal] or nil

local launcher = {}
local instance = nil

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

function launcher:filter()
	self.filtered = {}
	local filtered_any = {}
	local esc_input = helpers.lua_escape(self.input_grabber:get_input())

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
	self.entries_container:reset()

	for i, app in ipairs(self.filtered) do
		if i >= self.index_start and i <= self.index_start + self.rows - 1 then
			local entry_widget = wibox.widget {
				widget = wibox.container.background,
				forced_height = dpi(55),
				{
					widget = wibox.container.margin,
					margins = dpi(10),
					{
						widget = wibox.widget.textbox,
						markup = app:get_name()
					}
				}
			}

			entry_widget:buttons {
				awful.button({}, 1, function()
					if self.index_entry == i then
						app:launch()
						self:close()
					else
						self.index_entry = i
						self:update_entries()
					end
				end)
			}

			if i == self.index_entry then
				entry_widget.bg = beautiful.accent
				entry_widget.fg = beautiful.background
			end

			entry_widget:connect_signal("mouse::enter", function(w)
				if not (i == self.index_entry) then
					w.bg = beautiful.background_urgent
				end
			end)

			entry_widget:connect_signal("mouse::leave", function(w)
				if not (i == self.index_entry) then
					w.bg = beautiful.background
				end
			end)

			self.entries_container:add(entry_widget)
		end
	end
end

function launcher:open()
	if self.state then return end
	self.state = true
	self.popup_widget.placement = function(d)
		awful.placement.bottom_right(d, {
			honor_workarea = true,
			margins = beautiful.useless_gap*2
		})
	end
	self.popup_widget.visible = true
	self:emit_signal("state", self.state)
	self.unfiltered = Gio.AppInfo.get_all()
	self:filter()
	self:update_entries()
	self.input_grabber:run_keygrabber()
end

function launcher:close()
	if not self.state then return end
	self.state = false
	self.input_grabber:stop_keygrabber()
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

	ret.rows = 6

	ret.input_textbox = wibox.widget {
		widget = wibox.widget.textbox
	}

	ret.input_grabber = widgets.text_input {
		textbox = ret.input_textbox,
		start_prompt = text_icons.search .. " ",
		under_prompt = "Search...",
		cursor_bg = beautiful.foreground,
		cursor_fg = beautiful.background,
		under_prompt_fg = beautiful.foreground_alt,
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
				local desktop_app_info = Gio.DesktopAppInfo.new(Gio.AppInfo.get_id(app))
				local terminal = Gio.DesktopAppInfo.get_string(desktop_app_info, "Terminal") == "true" and true or false
				if terminal and terminal_command then
					awful.spawn(terminal_command .. app:get_executable())
				else
					app:launch()
				end
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

	ret.sidebar_control_button = widgets.hover_button {
		markup = text_icons.sliders,
		forced_width = dpi(55),
		forced_height = dpi(55),
		buttons = {
			awful.button({}, 1, function()
				control:open()
			end)
		}
	}

	ret.sidebar_settings_button = widgets.hover_button {
		markup = text_icons.gear,
		forced_width = dpi(55),
		forced_height = dpi(55),
		buttons = {
			awful.button({}, 1, function()
				helpers.spawn_once { "lxappearance" }
				ret:close()
			end)
		}
	}

	ret.sidebar_poweroff_button = widgets.hover_button {
		markup = text_icons.poweroff,
		forced_width = dpi(55),
		forced_height = dpi(55),
		fg_normal = beautiful.red,
		bg_hover = beautiful.red,
		buttons = {
			awful.button({}, 1, function()
				powermenu:open()
			end)
		}
	}

	ret.sidebar = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		forced_width = dpi(55),
		{
			layout = wibox.layout.align.vertical,
			ret.sidebar_poweroff_button,
			nil,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = beautiful.sep_width,
				spacing_widget = widgets.separator {
					dir = "h",
					margins = { left = dpi(10), right = dpi(10) }
				},
				ret.sidebar_settings_button,
				ret.sidebar_control_button
			}
		}
	}

	ret.entries_container = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		forced_width = dpi(290)
	}

	ret.entries_container:buttons {
		awful.button({}, 4, function()
			ret:back()
			ret:update_entries()
		end),
		awful.button({}, 5, function()
			ret:next()
			ret:update_entries()
		end),
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.margin,
		forced_width = dpi(290) + dpi(55) + dpi(10)*3,
		margins = dpi(10),
		{
			widget = wibox.container.background,
			forced_height = dpi(55)*(ret.rows + 1) + dpi(10),
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(10),
				fill_space = true,
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(10),
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
								bg = beautiful.background,
								{
									widget = wibox.container.margin,
									margins = { left = dpi(10), right = dpi(10) },
									ret.input_textbox
								}
							}
						}
					},
					ret.entries_container
				},
				ret.sidebar
			}
		}
	}

	ret.popup_widget = awful.popup {
		ontop = true,
		visible = false,
		screen = screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		widget = ret.main_widget
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
