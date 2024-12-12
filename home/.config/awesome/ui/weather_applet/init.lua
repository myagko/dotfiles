local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = require("beautiful").text_icons
local weather_daemon = require("daemons.weather")

local weather_applet = {}
local instance = nil

local desc_map = {
	[0] = "Clear sky",
	[1] = "Mainly clear",
	[2] = "Partly cloudy",
	[3] = "Overcast",
	[45] = "Fog",
	[48] = "Depositing\nrime fog",
	[51] = "Light drizzle",
	[53] = "Moderate drizzle",
	[55] = "Dense drizzle",
	[56] = "Light freezing\ndrizzle",
	[57] = "Dense freezing\ndrizzle",
	[61] = "Slight rain",
	[63] = "Moderate rain",
	[65] = "Heavy rain",
	[66] = "Light freezing\nrain",
	[67] = "Heavy freezing\nrain",
	[71] = "Slight\nsnow fall",
	[73] = "Moderate\nsnow fall",
	[75] = "Heavy snow\nfall",
	[77] = "Snow grains",
	[80] = "Slight rains\nshowers",
	[81] = "Moderate rain\nshowers",
	[82] = "Violent rain\nshowers",
	[85] = "Slight snow\nnshowers",
	[86] = "Heavy snow\nshowers",
	[95] = "Thunderstorm",
	[96] = "Thunderstorm\nwith slight hail",
	[99] = "Thunderstorm\nwith heavy hail"
}

local icon_map = {
	[0] = text_icons.no_cloud,
	[1] = text_icons.no_cloud,
	[2] = text_icons.cloud,
	[3] = text_icons.cloud,
	[45] = text_icons.mist,
	[48] = text_icons.mist,
	[51] = text_icons.rain,
	[53] = text_icons.rain,
	[55] = text_icons.rain,
	[56] = text_icons.rain,
	[57] = text_icons.rain,
	[61] = text_icons.rain,
	[63] = text_icons.rain,
	[65] = text_icons.rain,
	[66] = text_icons.rain,
	[67] = text_icons.rain,
	[71] = text_icons.snow,
	[73] = text_icons.snow,
	[75] = text_icons.snow,
	[77] = text_icons.snow,
	[80] = text_icons.shower_rain,
	[81] = text_icons.shower_rain,
	[82] = text_icons.shower_rain,
	[85] = text_icons.snow,
	[86] = text_icons.snow,
	[95] = text_icons.thunder,
	[96] = text_icons.thunder,
	[99] = text_icons.thunder
}

local function create_current(data)
	local temp_str = math.floor(data.current.temperature_2m) ..
		data.current_units.temperature_2m
	local desc_str = desc_map[data.current.weather_code]
	local icon_str = icon_map[data.current.weather_code]
	local wind_str = "Wind: " ..
		math.floor(data.current.wind_speed_10m) ..
		" " .. data.current_units.wind_speed_10m ..
		" (" .. helpers.to_direction(data.current.wind_direction_10m) .. ")"
	local humidity_str = "Humidity: " .. data.current.relative_humidity_2m ..
		data.current_units.relative_humidity_2m
	local pressure_str = "Pressure: " .. math.floor(data.current.surface_pressure) ..
		" " .. data.current_units.surface_pressure
	local feels_like_str = "Feels like: " .. math.floor(data.current.apparent_temperature) ..
		data.current_units.apparent_temperature

	return wibox.widget {
		widget = wibox.container.margin,
		margins = {
			left = dpi(15),
			right = dpi(25),
			top = dpi(15),
			bottom = dpi(10)
		},
		{
			layout = wibox.layout.fixed.horizontal,
			fill_space = true,
			{
				widget = wibox.widget.textbox,
				align = "left",
				markup = feels_like_str .. "\n" .. wind_str ..
					"\n" .. pressure_str .. "\n" .. humidity_str
			},
			{
				widget = wibox.widget.textbox,
				align = "right",
				markup = helpers.create_markup(icon_str .. " " .. temp_str, { size = "20pt" }) ..
					"\n" .. desc_str
			}
		}
	}
end

local function create_hourly(data)
	local step_width = dpi(40)
	local step_spacing = dpi(1)

	local temp_graph = wibox.widget {
		widget = wibox.widget.graph,
		forced_height = dpi(40),
		step_spacing = step_spacing,
		step_width = step_width,
		color = beautiful.accent,
		background_color = beautiful.background_alt
	}

	local temp_arr = {}

	for i = 24, 1, -1 do
		local temp = math.floor(data.hourly.temperature_2m[i])
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

	for i = 2, 24, 2 do
		local time_str = os.date("%H:%M", data.hourly.time[i])
		local temp_str = math.floor(data.hourly.temperature_2m[i]) ..
			data.hourly_units.temperature_2m

		time_layout:add(wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h0,
			markup = helpers.create_markup(time_str, { fg = beautiful.foreground_alt })
		})

		temp_layout:add(wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			markup = temp_str
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
				forced_width = dpi(24 * step_width + 23 * step_spacing),
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

local function create_daily(data)
	local day_layout = wibox.widget {
		layout = wibox.layout.overflow.horizontal,
		scrollbar_enabled = false,
		step = 40
	}

	for i = 1, 7 do
		local icon_str = icon_map[data.daily.weather_code[i]]
		local temp_str = math.floor(data.daily.temperature_2m_max[i]) ..
			data.daily_units.temperature_2m_max .. "\n" ..
			math.floor(data.daily.temperature_2m_min[i]) ..
			data.daily_units.temperature_2m_min
		local time_str = os.date("%a", data.daily.time[i])

		day_layout:add(wibox.widget {
			widget = wibox.container.background,
			forced_width = dpi(110),
			{
				widget = wibox.container.place,
				halign = "center",
				{
					layout = wibox.layout.fixed.vertical,
					{
						widget = wibox.widget.textbox,
						align = "center",
						font = beautiful.font_h0,
						markup = helpers.create_markup(time_str, { fg = beautiful.foreground_alt })
					},
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = dpi(7),
						{
							widget = wibox.widget.textbox,
							align = "center",
							markup = helpers.create_markup(icon_str, { size = "20pt" })
						},
						{
							widget = wibox.widget.textbox,
							align = "center",
							markup = temp_str
						}
					}
				}
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
		data = data[1] or data
		self.main_layout:add(
			create_current(data),
			create_hourly(data),
			widgets.separator {
				dir = "h",
				margins = {
					left = dpi(10),
					right = dpi(10)
				}
			},
			create_daily(data)
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
		forced_width = dpi(370),
		bg = beautiful.background_alt,
		ret.main_layout
	}

	weather_daemon:connect_signal("data_received", function(_, data)
		ret:setup_widget(data)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
