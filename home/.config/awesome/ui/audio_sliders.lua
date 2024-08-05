local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local Pulse = require("daemons.pulse")

local sliders = {}

sliders.vol_ico = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center"
}

sliders.vol_sli = wibox.widget {
	widget = wibox.widget.slider,
	maximum = 20,
	bar_height = dpi(7),
	handle_width = dpi(20),
	handle_border_width = dpi(2),
	handle_margins = { top = dpi(7), bottom = dpi(7) },
	bar_color = beautiful.background_urgent,
	handle_border_color = beautiful.background_alt
}

sliders.vol_perc = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center"
}

sliders.vol = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	fill_space = true,
	spacing = dpi(20),
	sliders.vol_ico,
	{
		widget = wibox.container.background,
		forced_width = dpi(310),
		forced_height = dpi(35),
		sliders.vol_sli
	},
	sliders.vol_perc
}

awesome.connect_signal("audio:vol_val", function(val)
	sliders.vol_sli.value = tonumber(val/5)
	sliders.vol_perc.text = val .. "%"
end)

awesome.connect_signal("audio:vol_mute", function(mute)
	if mute then
		sliders.vol_sli.bar_active_color = beautiful.foreground_alt
		sliders.vol_sli.handle_color = beautiful.foreground_alt
		sliders.vol_ico.text = text_icons.vol_off
	else
		sliders.vol_sli.bar_active_color = beautiful.accent
		sliders.vol_sli.handle_color = beautiful.accent
		sliders.vol_ico.text = text_icons.vol_on
	end
end)

sliders.vol_sli:connect_signal("property::value", function(_, new_value)
	sliders.vol_perc.text = tostring(new_value*5) .. "%"
	sliders.vol_sli.value = new_value
	Pulse.vol:set_value(new_value*5)
end)

sliders.vol_ico:buttons {
	awful.button({}, 1, function()
		Pulse.vol:toggle_mute()
		Pulse.vol:get_value()
	end)
}

sliders.mic_ico = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center"
}

sliders.mic_sli = wibox.widget {
	widget = wibox.widget.slider,
	maximum = 20,
	bar_height = dpi(7),
	handle_width = dpi(20),
	handle_border_width = dpi(2),
	handle_margins = { top = dpi(7), bottom = dpi(7) },
	bar_color = beautiful.background_urgent,
	handle_border_color = beautiful.background_alt
}

sliders.mic_perc = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center"
}

sliders.mic = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	fill_space = true,
	spacing = dpi(20),
	sliders.mic_ico,
	{
		widget = wibox.container.background,
		forced_width = dpi(310),
		forced_height = dpi(35),
		sliders.mic_sli
	},
	sliders.mic_perc
}

awesome.connect_signal("audio:mic_val", function(val)
	sliders.mic_sli.value = tonumber(val/5)
	sliders.mic_perc.text = val .. "%"
end)

awesome.connect_signal("audio:mic_mute", function(mute)
	if mute then
		sliders.mic_sli.bar_active_color = beautiful.foreground_alt
		sliders.mic_sli.handle_color = beautiful.foreground_alt
		sliders.mic_ico.text = text_icons.mic_off
	else
		sliders.mic_sli.bar_active_color = beautiful.accent
		sliders.mic_sli.handle_color = beautiful.accent
		sliders.mic_ico.text = text_icons.mic_on
	end
end)

sliders.mic_sli:connect_signal("property::value", function(_, new_value)
	sliders.mic_perc.text = tostring(new_value*5) .. "%"
	sliders.mic_sli.value = new_value
	Pulse.mic:set_value(new_value*5)
end)

sliders.mic_ico:buttons {
	awful.button({}, 1, function()
		Pulse.mic:toggle_mute()
		Pulse.mic:get_value()
	end)
}

sliders.main_widget = wibox.widget {
	widget = wibox.container.background,
	border_width = beautiful.comp_border_width,
	border_color = beautiful.border_color,
	bg = beautiful.background_alt,
	{
		widget = wibox.container.margin,
		margins = { left = dpi(20), right = dpi(20), top = dpi(10), bottom = dpi(10) },
		{
			layout = wibox.layout.fixed.vertical,
			sliders.vol,
			sliders.mic
		}
	}
}

return sliders
