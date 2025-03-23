local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local audio = require("services.audio")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi

local instance = nil

local function new()
	local ret = {}

	local speaker_widget = wibox.widget {
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
				bar_height = dpi(2),
				handle_width = dpi(20),
				handle_border_width = dpi(2),
				handle_margins = { top = dpi(7), bottom = dpi(7) },
				bar_color = beautiful.bg_urg,
				handle_color = beautiful.bg_alt,
				handle_border_color = beautiful.ac,
				handle_shape = beautiful.crcl(9),
				bar_shape = beautiful.rbar()
			}
		},
		{
			id = "value",
			widget = wibox.widget.textbox,
			align = "center"
		}
	}

	local speaker_icon = speaker_widget:get_children_by_id("icon")[1]
	local speaker_slider = speaker_widget:get_children_by_id("slider")[1]
	local speaker_value = speaker_widget:get_children_by_id("value")[1]

	audio:connect_signal("sink::value", function(_, _, val)
		speaker_slider:set_value(tonumber(val)/5)
		speaker_value:set_markup(val .. "%")
	end)

	audio:connect_signal("sink::mute", function(_, _, mute)
		if mute then
			speaker_icon:set_markup(text_icons.vol_off)
			speaker_slider:set_bar_active_color(beautiful.fg_alt)
			speaker_slider:set_handle_border_color(beautiful.fg_alt)
		else
			speaker_icon:set_markup(text_icons.vol_on)
			speaker_slider:set_bar_active_color(beautiful.ac)
			speaker_slider:set_handle_border_color(beautiful.ac)
		end
	end)

	speaker_slider:connect_signal("property::value", function(_, new_value)
		speaker_value:set_markup(tostring(new_value*5) .. "%")
		audio:set_sink_value("@DEFAULT_SINK@", new_value*5)
	end)

	speaker_icon:buttons {
		awful.button({}, 1, function()
			audio:toggle_sink_mute("@DEFAULT_SINK@")
			audio:get_sink_data("@DEFAULT_SINK@")
		end)
	}

	local microphone_widget = wibox.widget {
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
				bar_height = dpi(2),
				handle_width = dpi(20),
				handle_border_width = dpi(2),
				handle_margins = { top = dpi(7), bottom = dpi(7) },
				bar_color = beautiful.bg_urg,
				handle_color = beautiful.bg_alt,
				handle_border_color = beautiful.ac,
				handle_shape = beautiful.crcl(9),
				bar_shape = beautiful.rbar()
			}
		},
		{
			id = "value",
			widget = wibox.widget.textbox,
			align = "center"
		}
	}

	local microphone_icon = microphone_widget:get_children_by_id("icon")[1]
	local microphone_slider = microphone_widget:get_children_by_id("slider")[1]
	local microphone_value = microphone_widget:get_children_by_id("value")[1]

	audio:connect_signal("source::value", function(_, _, val)
		microphone_slider:set_value(tonumber(val)/5)
		microphone_value:set_markup(val .. "%")
	end)

	audio:connect_signal("source::mute", function(_, _, mute)
		if mute then
			microphone_icon:set_markup(text_icons.mic_off)
			microphone_slider:set_bar_active_color(beautiful.fg_alt)
			microphone_slider:set_handle_border_color(beautiful.fg_alt)
		else
			microphone_icon:set_markup(text_icons.mic_on)
			microphone_slider:set_bar_active_color(beautiful.ac)
			microphone_slider:set_handle_border_color(beautiful.ac)
		end
	end)

	microphone_slider:connect_signal("property::value", function(_, new_value)
		microphone_value:set_markup(tostring(new_value*5) .. "%")
		audio:set_source_value("@DEFAULT_SOURCE@", new_value*5)
	end)

	microphone_icon:buttons {
		awful.button({}, 1, function()
			audio:toggle_source_mute("@DEFAULT_SOURCE@")
			audio:get_source_data("@DEFAULT_SOURCE@")
		end)
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		shape = beautiful.rrect(dpi(10)),
		{
			widget = wibox.container.margin,
			margins = {
				left = dpi(20), right = dpi(20),
				top = dpi(10), bottom = dpi(10)
			},
			{
				layout = wibox.layout.fixed.vertical,
				speaker_widget,
				microphone_widget
			}
		}
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
