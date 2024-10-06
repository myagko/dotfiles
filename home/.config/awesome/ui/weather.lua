local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local weather_daemon = require("daemons.weather")
local dpi = beautiful.xresources.apply_dpi
local text_icons = require("beautiful").text_icons

local weather_applet = {}
local instance = nil

local icon_map = {
	["01d"] = text_icons.sun,
	["01n"] = text_icons.moon,
	["02d"] = text_icons.cloud,
	["02n"] = text_icons.cloud,
	["03d"] = text_icons.cloud,
	["03n"] = text_icons.cloud,
	["04d"] = text_icons.cloud,
	["04n"] = text_icons.cloud,
	["09d"] = text_icons.shower_rain,
	["09n"] = text_icons.shower_rain,
	["10d"] = text_icons.rain,
	["10n"] = text_icons.rain,
	["11d"] = text_icons.thunder,
	["11n"] = text_icons.thunder,
	["13d"] = text_icons.snow,
	["13n"] = text_icons.snow,
	["50d"] = text_icons.mist,
	["50n"] = text_icons.mist
}

local unit_map = {
	["metric"] = "°C",
	["imperial"] = "°F"
}

function weather_applet.create_current(data)
	local curr_temp = wibox.widget {
		widget = wibox.widget.textbox,
		align = "left",
		font = beautiful.font_h2,
		markup = icon_map[data.current.weather_icon] .. " "
			.. string.gsub(math.floor(data.current.temp), "%-0", "0") .. unit_map[data.units]
	}

	local curr_desc = wibox.widget {
		widget = wibox.widget.textbox,
		align = "left",
		wrap = "word",
		markup = data.current.weather_desc
	}

	local curr_feels_like = wibox.widget {
		widget = wibox.widget.textbox,
		align = "left",
		markup = "Feels like: " .. string.gsub(math.floor(data.current.feels_like), "%-0", "0")
			.. unit_map[data.units]
	}

	local curr_humidity = wibox.widget {
		widget = wibox.widget.textbox,
		align = "right",
		markup = "Humidity: " .. math.floor(data.current.humidity) .. "%"
	}

	local curr_wind = wibox.widget {
		widget = wibox.widget.textbox,
		align = "right",
		markup = "Wind: " .. math.floor(data.current.wind_speed)
			.. " m/s (" .. helpers.util.to_direction(data.current.wind_deg) .. ")"
	}

	local curr_uvi = wibox.widget {
		widget = wibox.widget.textbox,
		align = "right",
		markup = "UV index: " .. math.floor(data.current.uvi)
	}

	local curr_pressure = wibox.widget {
		widget = wibox.widget.textbox,
		align = "right",
		markup = "pressure: " .. math.floor(helpers.util.hPa_to_mmHg(data.current.pressure)) .. " mmHg"
	}

	return wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(15),
		{
			layout = wibox.layout.align.horizontal,
			{
				widget = wibox.container.background,
				forced_width = dpi(180),
				forced_height = dpi(130),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					curr_temp,
					curr_feels_like,
					curr_desc
				}
			},
			nil,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				curr_pressure,
				curr_wind,
				curr_humidity,
				curr_uvi
			}
		}
	}
end

function weather_applet.create_hourly(data)
	local step_width = dpi(20)
	local step_spacing = dpi(1)

	local temp_graph = wibox.widget {
		widget = wibox.widget.graph,
		forced_height = dpi(60),
		step_spacing = step_spacing,
		step_width = step_width,
		color = beautiful.accent,
		background_color = beautiful.background_alt
	}

	local temp_arr = {}

	for i = #data.hourly, 1, -1 do
		local temp = math.floor(data.hourly[i].temp)
		table.insert(temp_arr, temp)
		temp_graph:add_value(temp)
	end

	temp_graph.min_value = math.min(table.unpack(temp_arr)) - 1
	temp_graph.max_value = math.max(table.unpack(temp_arr)) + 1

	local time_layout = wibox.widget {
		layout = wibox.layout.flex.horizontal
	}

	local temp_layout = wibox.widget {
		layout = wibox.layout.flex.horizontal
	}

	for i = 2, #data.hourly, 4 do
		local hour = data.hourly[i]

		time_layout:add(wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			markup = os.date("%H:%M", hour.dt)
		})

		temp_layout:add(wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			markup = icon_map[hour.weather_icon] .. " " .. math.floor(hour.temp) .. "°"
		})
	end

	return wibox.widget {
		widget = wibox.container.margin,
		margins = { top = 0, bottom = dpi(15), left = dpi(15), right = dpi(15) },
		{
			layout = wibox.layout.overflow.horizontal,
			scrollbar_enabled = false,
			step = 40,
			{
				widget = wibox.container.background,
				forced_width = dpi(48*step_width + 47*step_spacing),
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					time_layout,
					temp_graph,
					temp_layout,
				}
			}
		}
	}
end

function weather_applet.create_daily(data)
	local day_layout = wibox.widget {
		layout = wibox.layout.overflow.horizontal,
		scrollbar_enabled = false,
		step = 40,
		spacing = dpi(5)
	}

	for _, v in ipairs(data.daily) do
		local temp = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			halign = "bottom",
			markup = string.gsub(math.floor(v.temp_day), "%-0", "0") .. "°/"
				.. string.gsub(math.floor(v.temp_night), "%-0", "0") .. "°"
		}

		local icon = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h3,
			markup = icon_map[v.weather_icon]
		}

		local day = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			markup = os.date("%a", v.dt)
		}

		day_layout:add(wibox.widget {
			widget = wibox.container.background,
			forced_width = dpi(100),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				day,
				icon,
				temp
			}
		})
	end

	return wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(15),
		day_layout
	}
end

function weather_applet:setup_widget(data)
	self.main_layout:reset()

	if data then
		self.main_layout:add(
			self.create_current(data),
			self.create_hourly(data),
			helpers.ui.create_sep {
				orientation = "h",
				size = beautiful.sep_width,
				margins = { left = dpi(10), right = dpi(10) }
			},
			self.create_daily(data)
		)
	else
		self.main_layout:add(self.err_msg)
	end
end



local function new()
	local ret = weather_applet

	ret.err_msg = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		fg = beautiful.foreground_alt,
		forced_height = dpi(100),
		{
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h2,
			markup = "No weather data"
		}
	}

	ret.main_layout = wibox.widget {
		layout = wibox.layout.fixed.vertical
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(450),
		bg = beautiful.background_alt,
		ret.main_layout
	}

	weather_daemon:connect_signal("weather::data", function(_, data)
		ret:setup_widget(data)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
