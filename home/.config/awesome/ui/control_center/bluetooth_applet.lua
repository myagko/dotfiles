local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local Bluetooth_daemon = require("daemons.bluetooth")

local Bluetooth_applet = {}

local function create_hover_button(widget)
	local box = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		fg = beautiful.foreground,
		forced_width = 55,
		forced_height = 55,
		widget
	}
	box:connect_signal("mouse::enter", function()
		box.bg = beautiful.accent
		box.fg = beautiful.background
	end)
	box:connect_signal("mouse::leave", function()
		box.bg = beautiful.background_alt
		box.fg = beautiful.foreground
	end)
	return box
end

Bluetooth_applet.b_close_button = create_hover_button(wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	font = helpers:inc_fontsize(1.5),
	text = ""
})

Bluetooth_applet.b_refresh_button = create_hover_button(wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	font = helpers:inc_fontsize(1.5),
	text = ""
})

Bluetooth_applet.b_toggle_button = create_hover_button(wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	font = helpers:inc_fontsize(4.5),
})

Bluetooth_applet.massage = wibox.widget {
	widget = wibox.container.background,
	fg = beautiful.foreground_alt,
	forced_height = 450,
	{
		widget = wibox.widget.textbox,
		align = "center",
		font = helpers:inc_fontsize(5),
	}
}

Bluetooth_applet.bottombar = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	forced_height = 55,
	{
		layout = wibox.layout.align.horizontal,
		Bluetooth_applet.b_toggle_button,
		nil,
		{
			layout = wibox.layout.fixed.horizontal,
			Bluetooth_applet.b_refresh_button,
			Bluetooth_applet.b_close_button
		},
	}
}

Bluetooth_applet.nt_container = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	Bluetooth_applet.massage
}

Bluetooth_applet.m_button_revealer = wibox.widget {
	widget = wibox.widget.textbox,
	text = ""
}

Bluetooth_applet.m_button_label = wibox.widget {
	widget = wibox.widget.textbox,
	text = " Disabled"
}

Bluetooth_applet.m_button = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	fg = beautiful.foreground,
	forced_height = 55,
	{
		widget = wibox.container.margin,
		margins = { left = 15, right = 15 },
		{
			layout = wibox.layout.align.horizontal,
			Bluetooth_applet.m_button_label,
			nil,
			Bluetooth_applet.m_button_revealer
		}
	}
}

Bluetooth_applet.main_widget = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	Bluetooth_applet.nt_container,
	Bluetooth_applet.bottombar
}

awesome.connect_signal("bluetooth:status", function(status)
	if status then
		Bluetooth_applet.massage.widget.text = "Devices list\n(WIP)"
		Bluetooth_applet.b_toggle_button.widget.text = ""
		Bluetooth_applet.m_button_label.text = " Enabled"
		Bluetooth_applet.m_button.bg = beautiful.accent
		Bluetooth_applet.m_button.fg = beautiful.background
	else
		Bluetooth_applet.b_toggle_button.widget.text = ""
		Bluetooth_applet.massage.widget.text = "Bluetooth disabled"
		Bluetooth_applet.m_button_label.text = " Disabled"
		Bluetooth_applet.m_button.bg = beautiful.background_alt
		Bluetooth_applet.m_button.fg = beautiful.foreground
	end
end)

Bluetooth_applet.b_toggle_button:buttons {
	awful.button({}, 1, function()
		Bluetooth_daemon:toggle()
	end)
}

Bluetooth_applet.m_button_label:buttons {
	awful.button({}, 1, function()
		Bluetooth_daemon:toggle()
	end)
}

return Bluetooth_applet
