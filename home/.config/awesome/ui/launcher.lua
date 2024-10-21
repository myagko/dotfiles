local awful = require("awful")
local wibox = require("wibox")
local Gio = require("lgi").Gio
local beautiful = require("beautiful")
local gears = require("gears")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local powermenu = require("ui.powermenu")
local control = require("ui.control")

local launcher = {}
local instance = nil

function launcher:next()
	if self.index_entry ~= #self.filtered and #self.filtered > 1 then
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
	if self.index_entry ~= 1 and #self.filtered > 1 then
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

function launcher.get_apps()
	local apps = {}
	for _, app in ipairs(Gio.AppInfo.get_all()) do
		if app:should_show() then
			table.insert(apps, {
				appinfo = app,
				name = app:get_name(),
				executable = app:get_executable()
			})
		end
	end

	return apps
end

function launcher:filter()
	local clear_input = self.input:gsub("[%[%]%(%)%.%-%+%?%*%%]", "%%%1")

	self.filtered = {}
	self.filtered_any = {}

	for _, entry in ipairs(self.unfiltered) do
		if entry.name:lower():sub(1, clear_input:len()) == clear_input:lower()
		or entry.executable:lower():sub(1, clear_input:len()) == clear_input:lower() then
			table.insert(self.filtered, entry)
		elseif entry.name:lower():match(clear_input:lower())
		or entry.executable:lower():sub(1, clear_input:len()) == clear_input:lower() then
			table.insert(self.filtered_any, entry)
		end
	end

	table.sort(self.filtered, function(a, b) return a.name:lower() < b.name:lower() end)
	table.sort(self.filtered_any, function(a, b) return a.name:lower() < b.name:lower() end)

	for i = 1, #self.filtered_any do
		self.filtered[#self.filtered + 1] = self.filtered_any[i]
	end
end

function launcher:update_entries()
	self.entries_container:reset()

	if self.index_entry > #self.filtered and #self.filtered ~= 0 then
		self.index_start, self.index_entry = 1, 1
	elseif self.index_entry < 1 then
		self.index_entry, self.index_start = 1, 1
	end

	for i, entry in ipairs(self.filtered) do
		local entry_widget = wibox.widget {
			forced_height = dpi(55),
			buttons = {
				awful.button({}, 1, function()
					if self.index_entry == i then
						entry.appinfo:launch()
						self:close()
					else
						self.index_entry = i
						self:filter()
						self:update_entries()
					end
				end),
				awful.button({}, 4, function()
					self:back()
					self:filter()
					self:update_entries()
				end),
				awful.button({}, 5, function()
					self:next()
					self:filter()
					self:update_entries()
				end),
			},
			widget = wibox.container.background,
			{
				widget = wibox.container.margin,
				margins = dpi(10),
				{
					widget = wibox.widget.textbox,
					markup = entry.name
				}
			}
		}

		if self.index_start <= i and i <= self.index_start + self.rows - 1 then
			self.entries_container:add(entry_widget)
		end

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
	end
end

function launcher:run_prompt()
	awful.prompt.run {
		prompt = "Search: ",
		textbox = self.prompt,
		bg_cursor = beautiful.foreground,
		done_callback = function()
			self:close()
		end,
		changed_callback = function(input)
			self.input = input
			self:filter()
			self:update_entries()
		end,
		exe_callback = function()
			if self.filtered[self.index_entry] then
				self.filtered[self.index_entry].appinfo:launch()
			end
		end,
		keypressed_callback = function(_, key)
			if key == "Down" then
				self:next()
			elseif key == "Up" then
				self:back()
			end
		end
	}
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
	self.index_start, self.index_entry = 1, 1
	self.unfiltered = self.get_apps()
	self.input = ""
	self:filter()
	self:update_entries()
	awful.keygrabber.stop()
	self:run_prompt()
end

function launcher:close()
	if not self.state then return end
	self.state = false
	awful.keygrabber.stop()
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
	local ret = gears.object {}
	gears.table.crush(ret, launcher, true)

	ret.rows = 6

	ret.sidebar_control_button = helpers.ui.create_hover_button {
		markup = text_icons.sliders,
		forced_width = dpi(55),
		forced_height = dpi(55),
		buttons = {
			awful.button({}, 1, function()
				control:open()
			end)
		}
	}

	ret.sidebar_settings_button = helpers.ui.create_hover_button {
		markup = text_icons.gear,
		forced_width = dpi(55),
		forced_height = dpi(55),
		buttons = {
			awful.button({}, 1, function()
				helpers.util.spawn_once { "lxappearance" }
				ret:close()
			end)
		}
	}

	ret.sidebar_poweroff_button = helpers.ui.create_hover_button {
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
				spacing_widget = helpers.ui.create_sep {
				orientation = "h",
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

	ret.prompt = wibox.widget {
		widget = wibox.widget.textbox
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
									ret.prompt
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
