local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")

local Weather = {}

local function to_direction(deg)
	-- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
	if deg == nil then
		return "Unknown dir"
	end

	local directions = {
		"N", "NNE", "NE", "ENE",
		"E", "ESE", "SE", "SSE",
		"S", "SSW", "SW", "WSW",
		"W", "WNW", "NW", "NNW",
		"N"
	}
	return directions[math.floor((deg%360)/22.5) + 1]
end

local sep = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_urgent,
	forced_height = beautiful.sep_width
}

Weather.curr_temp = wibox.widget {
	widget = wibox.widget.textbox,
	align = "right",
	font = helpers:inc_fontsize(16.5)
}

Weather.curr_icon = wibox.widget {
	widget = wibox.widget.textbox,
	font = helpers:inc_fontsize(36.5)
}

Weather.curr_desc = wibox.widget {
	widget = wibox.widget.textbox,
	font = helpers:inc_fontsize(6.5)
}

Weather.curr_humidity = wibox.widget {
	widget = wibox.widget.textbox,
	align = "right"
}

Weather.curr_wind = wibox.widget {
	widget = wibox.widget.textbox,
	align = "right"
}

Weather.curr_feels_like = wibox.widget {
	widget = wibox.widget.textbox,
	align = "right"
}

Weather.curr_loc_info = wibox.widget {
	widget = wibox.widget.textbox,
	font = helpers:inc_fontsize(-1.5)
}

Weather.curr_widget = wibox.widget {
	layout = wibox.layout.align.horizontal,
	nil,
	{
		layout = wibox.layout.fixed.vertical,
		spacing = 5,
		Weather.curr_icon,
		Weather.curr_desc,
		Weather.curr_loc_info
	},
	{
		layout = wibox.layout.fixed.vertical,
		spacing = 5,
		Weather.curr_temp,
		Weather.curr_feels_like,
		Weather.curr_wind,
		Weather.curr_humidity,
	}
}

function Weather:create_current(we)
	self.curr_temp.text = string.gsub(tostring(we.current.temp), "%-0", "0") .. "°C"
	self.curr_feels_like.text = "Feels like: " .. string.gsub(tostring(we.current.feels_like), "%-0", "0") .. "°C"
	self.curr_icon.text = we.current.icon
	self.curr_desc.text = we.current.desc
	self.curr_humidity.text = "Humidity: " .. we.current.humidity .. "%"
	self.curr_wind.text = "Wind: " .. we.current.wind_speed .. " m/s (" .. to_direction(we.current.wind_deg) .. ")"
	self.curr_loc_info.text = we.timezone

	return self.curr_widget
end


Weather.hour_widget = wibox.widget {
	layout = wibox.layout.overflow.horizontal,
	scrollbar_enabled = false,
	step = 40,
	spacing = 20,
}

function Weather:create_hourly(we)
	self.hour_widget:reset()

	for _, v in ipairs(we.hourly) do
		local temp = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			text = string.gsub(tostring(v.temp), "%-0", "0") .. "°"
		}

		local time = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			text = os.date("%R", v.dt)
		}

		local element = wibox.widget {
			widget = wibox.container.background,
			forced_width = 50,
			forced_height = 50,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = 5,
				time,
				temp
			}
		}

		self.hour_widget:add(element)
	end

	return self.hour_widget
end

Weather.day_widget = wibox.widget {
		layout = wibox.layout.overflow.horizontal,
		scrollbar_enabled = false,
		step = 40,
		spacing = 5,
	}

function Weather:create_daily(we)
	self.day_widget:reset()

	for _, v in ipairs(we.daily) do
		local temp = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			halign = "bottom",
			text = string.gsub(tostring(v.temp_day), "%-0", "0") .. "°/" .. string.gsub(tostring(v.temp_night), "%-0", "0") .. "°"
		}

		local icon = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			font = helpers:inc_fontsize(10),
			text = v.icon
		}

		local day = wibox.widget {
			widget = wibox.widget.textbox,
			align = "center",
			text = os.date("%a", v.dt)
		}

		local desc = wibox.widget {
			widget = wibox.widget.textbox,
			font = helpers:inc_fontsize(-2.5),
			align = "center",
			text = v.desc
		}

		local element = wibox.widget {
			widget = wibox.container.background,
			forced_width = 100,
			forced_height = 130,
			{
				layout = wibox.layout.align.vertical,
				day,
				{
					widget = wibox.container.place,
					halign = "center",
					valign = "center",
					{
						layout = wibox.layout.fixed.vertical,
						icon,
						desc,
					}
				},
				temp
			}
		}

		self.day_widget:add(element)
	end

	return self.day_widget
end

Weather.main_layout = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = 15
}

Weather.main_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	forced_width = 450,
	{
		widget = wibox.container.margin,
		margins = 20,
		Weather.main_layout
	}
}

awesome.connect_signal("daemons::weather", function(we)
	Weather.main_layout:reset()
	Weather.main_layout:add(Weather:create_current(we), Weather:create_hourly(we), sep, Weather:create_daily(we))
end)

return Weather
