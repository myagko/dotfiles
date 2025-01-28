local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local audio_daemon = require("daemons.audio")

local instance = nil

local function new()
	local ret = {}

	ret.vol_ico = wibox.widget {
		widget = wibox.widget.textbox,
		align = "center"
	}

	ret.vol_sli = wibox.widget {
		widget = wibox.widget.slider,
		maximum = 20,
		bar_height = dpi(7),
		handle_width = dpi(20),
		handle_border_width = dpi(4),
		handle_margins = { top = dpi(7), bottom = dpi(7) },
		bar_color = beautiful.bg_urg,
		handle_border_color = beautiful.bg_alt
	}

	ret.vol_perc = wibox.widget {
		widget = wibox.widget.textbox,
		align = "center"
	}

	ret.vol = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		fill_space = true,
		spacing = dpi(20),
		ret.vol_ico,
		{
			widget = wibox.container.background,
			forced_width = dpi(310),
			forced_height = dpi(35),
			ret.vol_sli
		},
		ret.vol_perc
	}

	audio_daemon:connect_signal("vol::value", function(_, val)
		ret.vol_sli.value = tonumber(val/5)
		ret.vol_perc.markup = val .. "%"
	end)

	audio_daemon:connect_signal("vol::mute", function(_, mute)
		if mute then
			ret.vol_sli.bar_active_color = beautiful.fg_alt
			ret.vol_sli.handle_color = beautiful.fg_alt
			ret.vol_ico.markup = text_icons.vol_off
		else
			ret.vol_sli.bar_active_color = beautiful.accent
			ret.vol_sli.handle_color = beautiful.accent
			ret.vol_ico.markup = text_icons.vol_on
		end
	end)

	ret.vol_sli:connect_signal("property::value", function(_, new_value)
		ret.vol_perc.markup = tostring(new_value*5) .. "%"
		ret.vol_sli.value = new_value
		audio_daemon:vol_set_value(new_value*5)
	end)

	ret.vol_ico:buttons {
		awful.button({}, 1, function()
			audio_daemon:vol_toggle_mute()
			audio_daemon:vol_get_value()
		end)
	}

	ret.mic_ico = wibox.widget {
		widget = wibox.widget.textbox,
		align = "center"
	}

	ret.mic_sli = wibox.widget {
		widget = wibox.widget.slider,
		maximum = 20,
		bar_height = dpi(7),
		handle_width = dpi(20),
		handle_border_width = dpi(4),
		handle_margins = { top = dpi(7), bottom = dpi(7) },
		bar_color = beautiful.bg_urg,
		handle_border_color = beautiful.bg_alt
	}

	ret.mic_perc = wibox.widget {
		widget = wibox.widget.textbox,
		align = "center"
	}

	ret.mic = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		fill_space = true,
		spacing = dpi(20),
		ret.mic_ico,
		{
			widget = wibox.container.background,
			forced_width = dpi(310),
			forced_height = dpi(35),
			ret.mic_sli
		},
		ret.mic_perc
	}

	audio_daemon:connect_signal("mic::value", function(_, val)
		ret.mic_sli.value = tonumber(val/5)
		ret.mic_perc.markup = val .. "%"
	end)

	audio_daemon:connect_signal("mic::mute", function(_, mute)
		if mute then
			ret.mic_sli.bar_active_color = beautiful.fg_alt
			ret.mic_sli.handle_color = beautiful.fg_alt
			ret.mic_ico.markup = text_icons.mic_off
		else
			ret.mic_sli.bar_active_color = beautiful.accent
			ret.mic_sli.handle_color = beautiful.accent
			ret.mic_ico.markup = text_icons.mic_on
		end
	end)

	ret.mic_sli:connect_signal("property::value", function(_, new_value)
		ret.mic_perc.markup = tostring(new_value*5) .. "%"
		ret.mic_sli.value = new_value
		audio_daemon:mic_set_value(new_value*5)
	end)

	ret.mic_ico:buttons {
		awful.button({}, 1, function()
			audio_daemon:mic_toggle_mute()
			audio_daemon:mic_get_value()
		end)
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		{
			widget = wibox.container.margin,
			margins = { left = dpi(20), right = dpi(20), top = dpi(10), bottom = dpi(10) },
			{
				layout = wibox.layout.fixed.vertical,
				ret.vol,
				ret.mic
			}
		}
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
