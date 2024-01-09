local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Pulse = require("daemons.pulse")

local vol_sli = wibox.widget {
	widget = wibox.widget.slider,
	maximum = 10,
	bar_height = 7,
	handle_width = 20,
	handle_border_width = 4,
	handle_margins = { top = 7, bottom = 7 },
	bar_color = beautiful.background_urgent,
	handle_border_color = beautiful.background_alt,
}

local vol_ico = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	markup = "v"
}

local vol_perc = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
}

local vol = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	fill_space = true,
	spacing = 20,
	vol_ico,
	{
		widget = wibox.container.background,
		forced_width = 310,
		forced_height = 35,
		vol_sli
	},
	vol_perc,
}

awesome.connect_signal("audio:vol_val", function(val)
	vol_sli.value = tonumber(val/10)
	vol_perc.markup = val .. "%"
end)

awesome.connect_signal("audio:vol_mute", function(mute)
	if mute then
		vol_sli.bar_active_color = beautiful.foreground_alt
		vol_sli.handle_color = beautiful.foreground_alt
		vol_ico.markup = ""
	else
		vol_sli.bar_active_color = beautiful.green
		vol_sli.handle_color = beautiful.green
		vol_ico.markup = ""
	end
end)

vol_sli:connect_signal("property::value", function(_, new_value)
	vol_perc.markup = tostring(new_value*10) .. "%"
	vol_sli.value = new_value
	Pulse:vol_set_val(new_value*10)
end)

vol_ico:buttons {
	awful.button({}, 1, function()
		Pulse:vol_set_mut()
		Pulse:vol_get()
	end)
}

local mic_sli = wibox.widget {
	widget = wibox.widget.slider,
	maximum = 10,
	bar_height = 7,
	handle_width = 20,
	handle_border_width = 4,
	handle_margins = { top = 7, bottom = 7 },
	bar_color = beautiful.background_urgent,
	handle_border_color = beautiful.background_alt,
}

local mic_ico = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
}

local mic_perc = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
}

awesome.connect_signal("audio:mic_val", function(val)
	mic_sli.value = tonumber(val/10)
	mic_perc.markup = val .. "%"
end)

awesome.connect_signal("audio:mic_mute", function(mute)
	if mute then
		mic_sli.bar_active_color = beautiful.foreground_alt
		mic_sli.handle_color = beautiful.foreground_alt
		mic_ico.markup = ""
	else
		mic_sli.bar_active_color = beautiful.yellow
		mic_sli.handle_color = beautiful.yellow
		mic_ico.markup = ""
	end
end)

mic_sli:connect_signal("property::value", function(_, new_value)
	mic_perc.markup = tostring(new_value*10) .. "%"
	mic_sli.value = new_value
	Pulse:mic_set_val(new_value*10)
end)

mic_ico:buttons {
	awful.button({}, 1, function()
		Pulse:mic_set_mut()
		Pulse:mic_get()
	end)
}

local mic = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	fill_space = true,
	spacing = 20,
	mic_ico,
	{
		widget = wibox.container.background,
		forced_width = 310,
		forced_height = 35,
		mic_sli
	},
	mic_perc,
}

local main_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	{
		widget = wibox.container.margin,
		margins = { left = 20, right = 20, top = 10, bottom = 10 },
		{
			layout = wibox.layout.fixed.vertical,
			vol,
			mic
		}
	}
}

return main_widget
