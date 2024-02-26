local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")

local Powermenu = {}

Powermenu.elements = {
	{
		exec = function()
			awful.spawn("poweroff")
		end,
		icon = "",
		color = beautiful.red
	},
	{
		exec = function()
			awful.spawn("reboot")
		end,
		icon = "",
		color = beautiful.yellow
	},
	{
		exec = function()
			awesome.quit()
		end,
		icon = "",
		color = beautiful.green
	}
}

Powermenu.elements_container = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	spacing = beautiful.powermenu_margins
}

Powermenu.prompt = wibox.widget {
	widget = wibox.widget.textbox,
	visible = false
}

Powermenu.main_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background,
	forced_width = beautiful.powermenu_item_size*3 + beautiful.powermenu_margins*5,
	forced_height = beautiful.powermenu_item_size + beautiful.powermenu_margins*3,
	{
		widget = wibox.container.margin,
		margins = beautiful.powermenu_margins*1.5,
		{
			layout = wibox.layout.fixed.vertical,
			Powermenu.prompt,
			Powermenu.elements_container
		}
	}
}

Powermenu.popup_widget = awful.popup {
	visible = false,
	ontop = true,
	widget = {
		widget = wibox.container.background,
		bg = beautiful.background_urgent,
		{
			widget = wibox.container.margin,
			margins = beautiful.border_width,
			{
				widget = wibox.container.background,
				bg = beautiful.background,
				Powermenu.main_widget
			}
		}
	}
}

function Powermenu:next()
	if self.index_element ~= #self.elements then
		self.index_element = self.index_element + 1
	else
		self.index_element = 1
	end
end

function Powermenu:back()
	if self.index_element ~= 1 then
		self.index_element = self.index_element - 1
	else
		self.index_element = #self.elements
	end
end

function Powermenu:add_elements()
	self.elements_container:reset()

	for i, element in ipairs(self.elements) do
		local element_widget = wibox.widget {
			widget = wibox.container.background,
			forced_width = beautiful.powermenu_item_size,
			forced_height = beautiful.powermenu_item_size,
			buttons = {
				awful.button({}, 1, function()
					if self.index_element == i then
						element:exec()
					else
						self.index_element = i
						self:add_elements()
					end
				end)
			},
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = helpers:inc_fontsize(beautiful.powermenu_icon_size),
				markup = element.icon
			}
		}

		if i == self.index_element then
			element_widget.bg = element.color
			element_widget.fg = beautiful.background
		end

		self.elements_container:add(element_widget)
	end
	collectgarbage("collect")
end

function Powermenu:send_signal()
	awesome.emit_signal("powermenu:state", self.state)
end

function Powermenu:open()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:send_signal()

	self.index_element = 1
	self:add_elements()

	awful.keygrabber.stop()
	awful.prompt.run {
		textbox = self.prompt,
		exe_callback = function()
			self.elements[self.index_element]:exec()
		end,
		changed_callback = function()
			self:add_elements()
		end,
		keypressed_callback = function(_, key)
			if key == "Right" or key == "Down" then
				self:next()
			elseif key == "Left" or key == "Up" then
				self:back()
			end
		end,
		done_callback = function()
			self:close()
		end
	}

	self.popup_widget.placement = function(d)
		awful.placement.centered(d)
	end
end

function Powermenu:close()
	if not self.state then return end
	self.state = false
	awful.keygrabber.stop()
	self.popup_widget.visible = false
	self:send_signal()
end

function Powermenu:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

awesome.connect_signal("launcher:state", function(state)
	if state then
		Powermenu:close()
	end
end)

awesome.connect_signal("control_center:state", function(state)
	if state then
		Powermenu:close()
	end
end)

return Powermenu
