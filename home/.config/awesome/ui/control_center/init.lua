local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")

local Pulse = require("daemons.pulse")
local Notifs_list = require("ui.control_center.notification_list")
local Wifi = require("ui.control_center.wifi_applet")
local Sliders = require("ui.control_center.audio_sliders")
local Bluetooth = require("ui.control_center.bluetooth_applet")
local Calendar = require("ui.control_center.calendar")
local Weather = require("ui.control_center.weather_applet")

local Control_center = {}

local main_sep = helpers:create_sep("h", beautiful.sep_width)

local controls = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = beautiful.ctrl_center_margins,
	Sliders,
	{
		layout = wibox.layout.flex.horizontal,
		spacing = beautiful.ctrl_center_margins,
		Wifi.m_button,
		Bluetooth.m_button
	}
}

Control_center.main_widget = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = beautiful.ctrl_center_margins,
}

Wifi.m_button_revealer:buttons {
	awful.button({}, 1, function()
		Control_center.main_widget:reset()
		Control_center.main_widget:add(Wifi.main_widget)
	end)
}

Wifi.b_close_button:buttons {
	awful.button({}, 1, function()
		Wifi:refresh()
		Control_center.main_widget:reset()
		Control_center.main_widget:add(Notifs_list, main_sep, controls)
	end)
}

Bluetooth.m_button_revealer:buttons {
	awful.button({}, 1, function()
		Control_center.main_widget:reset()
		Control_center.main_widget:add(Bluetooth.main_widget)
	end)
}

Bluetooth.b_close_button:buttons {
	awful.button({}, 1, function()
		Control_center.main_widget:reset()
		Control_center.main_widget:add(Notifs_list, main_sep, controls)
	end)
}

Control_center.popup_widget = awful.popup {
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
				{
					widget = wibox.container.margin,
					margins = beautiful.ctrl_center_margins*2,
					Control_center.main_widget
				}
			}
		}
	}
}

function Control_center:send_signal()
	awesome.emit_signal("control_center:state", self.state)
end

function Control_center:close()
	if not self.state then return end
	self.state = false
	self.popup_widget.visible = false
	self.main_widget:reset()
	if Wifi.passbox.state then
		Wifi:close_passbox()
	end
	self:send_signal()
end

function Control_center:open(mode)
	mode = mode or "main"
	if self.state == mode then return end
	self.state = mode
	if mode == "main" then
		Pulse:vol_get()
		Pulse:mic_get()
		self.main_widget:reset()
		self.main_widget:add(Notifs_list, main_sep, controls)
	elseif mode == "daily" then
		self.main_widget:reset()
		Calendar:set(os.date("*t"))
		self.main_widget:add(Weather.main_widget, Calendar.main_widget)
	end
	self.popup_widget.visible = true
	self:send_signal()
	self.popup_widget.placement = function(d)
		awful.placement.bottom_right(d, { honor_workarea = true, margins = beautiful.useless_gap * 2 })
	end
end

function Control_center:toggle(mode)
	if not self.popup_widget.visible then
		self:open(mode)
	else
		self:close()
	end
end

awesome.connect_signal("launcher:state", function(state)
	if state then
		Control_center:close()
	end
end)

awesome.connect_signal("powermenu:state", function(state)
	if state then
		Control_center:close()
	end
end)

return Control_center
