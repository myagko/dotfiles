local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local Notification_list = require("ui.notification_list")
local Audio_sliders = require("ui.audio_sliders")
local Wifi_applet = require("ui.wifi")
local Bluetooth_applet = require("ui.bluetooth")
local Pulse = require("daemons.pulse")

local control = {}

control.main_layout = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = dpi(10)
}

control.popup_widget = awful.popup {
	visible = false,
	ontop = true,
	screen = screen.primary,
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
					margins = dpi(20),
					control.main_layout
				}
			}
		}
	}
}

Wifi_applet.control_button:get_revealer():buttons {
	awful.button({}, 1, function()
		control.main_layout:reset()
		control.main_layout:add(Wifi_applet.main_widget)
	end)
}

Wifi_applet.bottombar_close_button:buttons {
	awful.button({}, 1, function()
		control:restore_widgets()
	end)
}

Bluetooth_applet.control_button:get_revealer():buttons {
	awful.button({}, 1, function()
		control.main_layout:reset()
		control.main_layout:add(Bluetooth_applet.main_widget)
	end)
}

Bluetooth_applet.bottombar_close_button:buttons {
	awful.button({}, 1, function()
		control:restore_widgets()
	end)
}

function control:restore_widgets()
	self.main_layout:reset()
	self.main_layout:add(
		Notification_list.main_widget,
		helpers.ui.create_sep { orientation = "h", size = beautiful.sep_width },
		Audio_sliders.main_widget,
		wibox.widget {
			layout = wibox.layout.flex.horizontal,
			spacing = dpi(10),
			Wifi_applet.control_button,
			Bluetooth_applet.control_button
		}
	)
end

function control:open()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:send_state()
	self.popup_widget.placement = function(d)
		awful.placement.bottom_right(d, { honor_workarea = true, margins = beautiful.useless_gap * 2 })
	end
	Pulse:get_all()
	self:restore_widgets()
end

function control:close()
	if not self.state then return end

	Wifi_applet:close_ap_menu()

	self.state = false
	self.popup_widget.visible = false
	self:send_state()
end

function control:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

function control:send_state()
	awesome.emit_signal("control:state", self.state)
end

return control
