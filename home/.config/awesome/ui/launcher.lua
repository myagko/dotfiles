local awful = require("awful")
local wibox = require("wibox")
local Gio = require("lgi").Gio
local beautiful = require("beautiful")

local Powermenu = require("ui.powermenu")
local Control_center = require("ui.control_center")

local Launcher = {}
local Sidebar = {}

local function create_hover_button(widget, color, fg)
	local box = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		fg = fg or beautiful.foreground,
		forced_width = 55,
		forced_height = 55,
		widget
	}
	box:connect_signal("mouse::enter", function()
		box.bg = color
		box.fg = beautiful.background
	end)
	box:connect_signal("mouse::leave", function()
		box.bg = beautiful.background_alt
		box.fg = fg or beautiful.foreground
	end)
	return box
end

Sidebar.control_center_button = create_hover_button(
	wibox.widget {
		widget = wibox.widget.textbox,
		text = "",
		align = "center"
	},
	beautiful.accent, beautiful.foreground
)

Sidebar.restart_button = create_hover_button(
	wibox.widget {
		widget = wibox.widget.textbox,
		text = "",
		align = "center"
	},
	beautiful.accent, beautiful.foreground
)

Sidebar.poweroff_button = create_hover_button(
	wibox.widget {
		widget = wibox.widget.textbox,
		text = "",
		align = "center"
	},
	beautiful.red, beautiful.red
)

Sidebar.control_center_button.buttons = {
	awful.button({}, 1, function()
		Control_center:open()
	end)
}

Sidebar.restart_button.buttons = {
	awful.button({}, 1, function()
		awesome.restart()
	end)
}

Sidebar.poweroff_button.buttons = {
	awful.button({}, 1, function()
		Powermenu:open()
	end)
}

Sidebar.m_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	forced_width = 55,
	{
		layout = wibox.layout.align.vertical,
		Sidebar.control_center_button,
		nil,
		{
			layout = wibox.layout.fixed.vertical,
			Sidebar.restart_button,
			Sidebar.poweroff_button
		}
	}
}

Launcher.prompt = wibox.widget {
	widget = wibox.widget.textbox
}

Launcher.promptbox = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.border_color,
	forced_height = 55,
	forced_width = 290,
	buttons = {
		awful.button({}, 1, function()
			Launcher:run_prompt()
		end)
	},
	{
		widget = wibox.container.margin,
		margins = { bottom = beautiful.sep_width },
		{
			widget = wibox.container.background,
			bg = beautiful.background,
			{
				widget = wibox.container.margin,
				margins = { left = 10, right = 10 },
				Launcher.prompt
			}
		}
	}
}

Launcher.entries_container = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	forced_width = 290
}

Launcher.main_widget = wibox.widget {
	widget = wibox.container.margin,
	forced_width = 290 + 55 + 10*3,
	margins = 10,
	{
		widget = wibox.container.background,
		forced_height = (55 * (6 + 1)) + 10,
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = 10,
			fill_space = true,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = 10,
				Launcher.promptbox,
				Launcher.entries_container
			},
			Sidebar.m_widget
		}
	}
}

Launcher.popup_widget = awful.popup {
	ontop = true,
	visible = false,
	widget = {
		widget = wibox.container.background,
		bg = beautiful.background_urgent,
		{
			widget = wibox.container.margin,
			margins = beautiful.border_width,
			{
				widget = wibox.container.background,
				bg = beautiful.background,
				Launcher.main_widget
			}
		}
	}
}

function Launcher:next()
	if self.index_entry ~= #self.filtered and #self.filtered > 1 then
		self.index_entry = self.index_entry + 1
		if self.index_entry > self.index_start + 6 - 1 then
			self.index_start = self.index_start + 1
		end
	else
		self.index_entry = 1
		self.index_start = 1
	end
end

function Launcher:back()
	if self.index_entry ~= 1 and #self.filtered > 1 then
		self.index_entry = self.index_entry - 1
		if self.index_entry < self.index_start then
			self.index_start = self.index_start - 1
		end
	else
		self.index_entry = #self.filtered
		if #self.filtered < 6 then
			self.index_start = 1
		else
			self.index_start = #self.filtered - 6 + 1
		end
	end
end

function Launcher:get_apps()
	local entries = {}
	for _, entry in ipairs(Gio.AppInfo.get_all()) do
		if entry:should_show() then
			local name = entry:get_name():gsub("&", "&amp;"):gsub("<", "&lt;"):gsub("'", "&#39;")
			table.insert(entries, { name = name, appinfo = entry })
		end
	end
	return entries
end

function Launcher:filter()
	local clear_input = self.input:gsub("[%(%)%[%]%%]", "")

	self.filtered = {}
	self.regfiltered = {}

	for _, entry in ipairs(self.unfiltered) do
		if entry.name:lower():sub(1, clear_input:len()) == clear_input:lower() then
			table.insert(self.filtered, entry)
		elseif entry.name:lower():match(clear_input:lower()) then
			table.insert(self.regfiltered, entry)
		end
	end

	table.sort(self.filtered, function(a, b) return a.name:lower() < b.name:lower() end)
	table.sort(self.regfiltered, function(a, b) return a.name:lower() < b.name:lower() end)

	for i = 1, #self.regfiltered do
		self.filtered[#self.filtered + 1] = self.regfiltered[i]
	end
end

function Launcher:add_entries()
	self.entries_container:reset()

	if self.index_entry > #self.filtered and #self.filtered ~= 0 then
		self.index_start, self.index_entry = 1, 1
	elseif self.index_entry < 1 then
		self.index_entry, self.index_start = 1, 1
	end

	for i, entry in ipairs(self.filtered) do
		local entry_widget = wibox.widget {
			forced_height = 55,
			buttons = {
				awful.button({}, 1, function()
					if self.index_entry == i then
						entry.appinfo:launch()
						self:close()
					else
						self.index_entry = i
						self:filter()
						self:add_entries()
					end
				end),
				awful.button({}, 4, function()
					self:back()
					self:filter()
					self:add_entries()
				end),
				awful.button({}, 5, function()
					self:next()
					self:filter()
					self:add_entries()
				end),
			},
			widget = wibox.container.background,
			{
				margins = 10,
				widget = wibox.container.margin,
				{
					markup = entry.name,
					widget = wibox.widget.textbox,
				}
			}
		}

		if self.index_start <= i and i <= self.index_start + 6 - 1 then
			self.entries_container:add(entry_widget)
		end

		if i == self.index_entry then
			entry_widget.bg = beautiful.accent
			entry_widget.fg = beautiful.background
		end
	end

	collectgarbage("collect")
end

function Launcher:send_signal()
	awesome.emit_signal("launcher:state", self.state)
end

function Launcher:run_prompt()
	awful.prompt.run {
		prompt = "Launch: ",
		textbox = self.prompt,
		bg_cursor = beautiful.foreground,
		done_callback = function()
			self:close()
		end,
		changed_callback = function(input)
			self.input = input
			self:filter()
			self:add_entries()
		end,
		exe_callback = function(input)
			if self.filtered[self.index_entry] then
				self.filtered[self.index_entry].appinfo:launch()
			else
				awful.spawn.with_shell(input)
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

function Launcher:open()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:send_signal()

	self.index_start, self.index_entry = 1, 1
	self.unfiltered = self:get_apps()

	self.input = ""
	self:filter()
	self:add_entries()

	awful.keygrabber.stop()
	self:run_prompt()

	self.popup_widget.placement = function(d)
		awful.placement.bottom_right(d, { honor_workarea = true, margins = beautiful.useless_gap*2 })
	end
end

function Launcher:close()
	if not self.state then return end
	self.state = false
	awful.keygrabber.stop()
	self.popup_widget.visible = false
	self:send_signal()
end

function Launcher:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

awesome.connect_signal("powermenu:state", function(state)
	if state then
		Launcher:close()
	end
end)

awesome.connect_signal("control_center:state", function(state)
	if state then
		Launcher:close()
	end
end)

return Launcher
