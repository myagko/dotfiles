local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi
local notification_list = require("ui.notification_list")
local audio_sliders = require("ui.audio_sliders")
local wifi_applet = require("ui.wifi")
local bluetooth_applet = require("ui.bluetooth")
local audio_daemon = require("daemons.audio")

local control = {}
local instance = nil

function control:restore_widgets()
	self.main_layout:reset()
	self.main_layout:add(
		notification_list.main_widget,
		helpers.ui.create_sep { orientation = "h", size = beautiful.sep_width },
		audio_sliders.main_widget,
		wibox.widget {
			layout = wibox.layout.flex.horizontal,
			spacing = dpi(10),
			wifi_applet.control_button,
			bluetooth_applet.control_button
		}
	)
end

function control:open()
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
	audio_daemon:vol_get_value()
	audio_daemon:mic_get_value()
	self:restore_widgets()
end

function control:close()
	if not self.state then return end
	self.state = false
	self.popup_widget.visible = false
	self:emit_signal("state", self.state)
	wifi_applet:close_ap_menu()
end

function control:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

local function new()
	local ret = gears.object {}
	gears.table.crush(ret, control, true)

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
		widget = {
			widget = wibox.container.margin,
			margins = dpi(20),
			ret.main_layout
		}
	}

	wifi_applet.control_button_revealer:buttons {
		awful.button({}, 1, function()
			ret.main_layout:reset()
			ret.main_layout:add(wifi_applet.main_widget)
		end)
	}

	wifi_applet.bottombar_close_button:buttons {
		awful.button({}, 1, function()
			ret:restore_widgets()
		end)
	}

	bluetooth_applet.control_button_revealer:buttons {
		awful.button({}, 1, function()
			ret.main_layout:reset()
			ret.main_layout:add(bluetooth_applet.main_widget)
		end)
	}

	bluetooth_applet.bottombar_close_button:buttons {
		awful.button({}, 1, function()
			ret:restore_widgets()
		end)
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
