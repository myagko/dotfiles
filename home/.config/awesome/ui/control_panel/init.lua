local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local common = require("common")
local gobject = require("gears.object")
local gtable = require("gears.table")
local audio = require("services.audio")
local dpi = beautiful.xresources.apply_dpi
local capi = { screen = screen }

local notification_list = require("ui.control_panel.notification_list")
local audio_sliders = require("ui.control_panel.audio_sliders")
local wifi_applet = require("ui.control_panel.wifi_applet")
local bluetooth_applet = require("ui.control_panel.bluetooth_applet")

local control_panel = {}
local instance = nil

function control_panel:setup_wifi()
	local main_layout = self.main_widget:get_children_by_id("main_layout")[1]
	main_layout:reset()
	main_layout:add(wifi_applet.main_widget)
end

function control_panel:setup_bluetooth()
	local main_layout = self.main_widget:get_children_by_id("main_layout")[1]
	main_layout:reset()
	main_layout:add(bluetooth_applet.main_widget)
end

function control_panel:setup_controls()
	local main_layout = self.main_widget:get_children_by_id("main_layout")[1]
	main_layout:reset()
	main_layout:add(
		notification_list.main_widget,
		wibox.widget {
			widget = wibox.container.background,
			forced_width = 1,
			forced_height = beautiful.separator_thickness,
			{
				widget = wibox.widget.separator,
				orientation = "horizontal"
			}
		},
		audio_sliders.main_widget,
		wibox.widget {
			layout = wibox.layout.flex.horizontal,
			spacing = dpi(6),
			wifi_applet.control_button,
			bluetooth_applet.control_button
		}
	)
end

function control_panel:open()
	if self.state then return end
	self.state = true
	audio:get_sink_data("@DEFAULT_SINK@")
	audio:get_source_data("@DEFAULT_SOURCE@")
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

	ret.main_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(15),
		{
			id = "main_layout",
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(6)
		}
	}

	ret.popup_widget = awful.popup {
		visible = false,
		ontop = true,
		screen = capi.screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color_normal,
		shape = beautiful.rrect(dpi(25)),
		placement = function(d)
			awful.placement.bottom_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap*2
			})
		end,
		widget = ret.main_widget
	}

	wifi_applet.control_button:get_children_by_id("revealer")[1]:buttons {
		awful.button({}, 1, function()
			ret:setup_wifi()
		end)
	}

	wifi_applet.bottombar:get_children_by_id("close_button")[1]:buttons {
		awful.button({}, 1, function()
			ret:setup_controls()
		end)
	}

	bluetooth_applet.control_button:get_children_by_id("revealer")[1]:buttons {
		awful.button({}, 1, function()
			ret:setup_bluetooth()
		end)
	}

	bluetooth_applet.bottombar:get_children_by_id("close_button")[1]:buttons {
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
