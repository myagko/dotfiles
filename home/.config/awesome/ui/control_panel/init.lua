local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local gobject = require("gears.object")
local gtable = require("gears.table")
local dpi = beautiful.xresources.apply_dpi
local audio_daemon = require("daemons.audio")
local notification_list = require("ui.control_panel.notification_list")
local audio_sliders = require("ui.control_panel.audio_sliders")
local wifi_applet = require("ui.control_panel.wifi_applet")
local bluetooth_applet = require("ui.control_panel.bluetooth_applet")

local control_panel = {}
local instance = nil

function control_panel:setup_wifi()
	self.main_layout:reset()
	self.main_layout:add(wifi_applet.main_widget)
end

function control_panel:setup_bluetooth()
	self.main_layout:reset()
	self.main_layout:add(bluetooth_applet.main_widget)
end

function control_panel:setup_controls()
	self.main_layout:reset()
	self.main_layout:add(
		notification_list.main_widget,
		widgets.separator {
			dir = "h",
			size = beautiful.sep_width
		},
		audio_sliders.main_widget,
		wibox.widget {
			layout = wibox.layout.flex.horizontal,
			spacing = dpi(10),
			wifi_applet.control_button,
			bluetooth_applet.control_button
		}
	)
end

function control_panel:open()
	if self.state then return end
	self.state = true
	audio_daemon:vol_get()
	audio_daemon:mic_get()
	self:setup_controls()
	self.popup_widget.visible = true
	self:emit_signal("state", self.state)
end

function control_panel:close()
	if not self.state then return end
	self.state = false
	wifi_applet:close_ap_menu()
	self.popup_widget.visible = false
	self:emit_signal("state", self.state)
end

function control_panel:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, control_panel, true)

	ret.main_layout = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(10)
	}

	ret.popup_widget = awful.popup {
		visible = false,
		ontop = true,
		screen = screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		placement = function(d)
			awful.placement.bottom_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap*2
			})
		end,
		widget = {
			widget = wibox.container.margin,
			margins = dpi(20),
			ret.main_layout
		}
	}

	wifi_applet.control_button_revealer:buttons {
		awful.button({}, 1, function()
			ret:setup_wifi()
		end)
	}

	wifi_applet.bottombar_close_button:buttons {
		awful.button({}, 1, function()
			ret:setup_controls()
		end)
	}

	bluetooth_applet.control_button_revealer:buttons {
		awful.button({}, 1, function()
			ret:setup_bluetooth()
		end)
	}

	bluetooth_applet.bottombar_close_button:buttons {
		awful.button({}, 1, function()
			ret:setup_controls()
		end)
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
