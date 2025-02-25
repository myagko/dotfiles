local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local audio_daemon = require("daemons.audio")

local instance = nil

local function new()
	local ret = {}

	local volume_widget = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		fill_space = true,
		spacing = dpi(20),
		{
			id = "icon",
			widget = wibox.widget.textbox,
			align = "center"
		},
		{
			widget = wibox.container.background,
			forced_width = dpi(310),
			forced_height = dpi(35),
			{
				id = "slider",
				widget = wibox.widget.slider,
				maximum = 20,
				bar_height = dpi(7),
				handle_width = dpi(20),
				handle_border_width = dpi(4),
				handle_margins = { top = dpi(7), bottom = dpi(7) },
				bar_color = beautiful.bg_urg,
				handle_border_color = beautiful.bg_alt
			}
		},
		{
			id = "value",
			widget = wibox.widget.textbox,
			align = "center"
		}
	}

	local volume_icon = volume_widget:get_children_by_id("icon")[1]
	local volume_slider = volume_widget:get_children_by_id("slider")[1]
	local volume_value = volume_widget:get_children_by_id("value")[1]

	audio_daemon:connect_signal("vol::value", function(_, val)
		volume_slider:set_value(tonumber(val)/5)
		volume_value:set_markup(val .. "%")
	end)

	audio_daemon:connect_signal("vol::mute", function(_, mute)
		if mute then
			volume_icon:set_markup(text_icons.vol_off)
			volume_slider:set_bar_active_color(beautiful.fg_alt)
			volume_slider:set_handle_color(beautiful.fg_alt)
		else
			volume_icon:set_markup(text_icons.vol_on)
			volume_slider:set_bar_active_color(beautiful.accent)
			volume_slider:set_handle_color(beautiful.accent)
		end
	end)

	volume_slider:connect_signal("property::value", function(_, new_value)
		volume_value:set_markup(tostring(new_value*5) .. "%")
		audio_daemon:vol_set_value(new_value*5)
	end)

	volume_icon:buttons {
		awful.button({}, 1, function()
			audio_daemon:vol_toggle_mute()
			audio_daemon:vol_get_data()
		end)
	}

	local micro_widget = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		fill_space = true,
		spacing = dpi(20),
		{
			id = "icon",
			widget = wibox.widget.textbox,
			align = "center"
		},
		{
			widget = wibox.container.background,
			forced_width = dpi(310),
			forced_height = dpi(35),
			{
				id = "slider",
				widget = wibox.widget.slider,
				maximum = 20,
				bar_height = dpi(7),
				handle_width = dpi(20),
				handle_border_width = dpi(4),
				handle_margins = { top = dpi(7), bottom = dpi(7) },
				bar_color = beautiful.bg_urg,
				handle_border_color = beautiful.bg_alt
			}
		},
		{
			id = "value",
			widget = wibox.widget.textbox,
			align = "center"
		}
	}

	local micro_icon = micro_widget:get_children_by_id("icon")[1]
	local micro_slider = micro_widget:get_children_by_id("slider")[1]
	local micro_value = micro_widget:get_children_by_id("value")[1]

	audio_daemon:connect_signal("mic::value", function(_, val)
		micro_slider:set_value(tonumber(val)/5)
		micro_value:set_markup(val .. "%")
	end)

	audio_daemon:connect_signal("mic::mute", function(_, mute)
		if mute then
			micro_icon:set_markup(text_icons.mic_off)
			micro_slider:set_bar_active_color(beautiful.fg_alt)
			micro_slider:set_handle_color(beautiful.fg_alt)
		else
			micro_icon:set_markup(text_icons.mic_on)
			micro_slider:set_bar_active_color(beautiful.accent)
			micro_slider:set_handle_color(beautiful.accent)
		end
	end)

	micro_slider:connect_signal("property::value", function(_, new_value)
		micro_value:set_markup(tostring(new_value*5) .. "%")
		audio_daemon:mic_set_value(new_value*5)
	end)

	micro_icon:buttons {
		awful.button({}, 1, function()
			audio_daemon:mic_toggle_mute()
			audio_daemon:mic_get_data()
		end)
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		{
			widget = wibox.container.margin,
			margins = {
				left = dpi(20),
				right = dpi(20),
				top = dpi(10),
				bottom = dpi(10)
			},
			{
				layout = wibox.layout.fixed.vertical,
				volume_widget,
				micro_widget
			}
		}
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
