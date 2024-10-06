local gears = require("gears")
local json = require("modules.json")
local helpers = require("helpers")
local user = require("user")

local weather_daemon = {}
local instance = nil

function weather_daemon:extract_data(out)
	local data = {
		units = self.units,
		current = {},
		hourly = {},
		daily = {}
	}

	if out == "" then
		data = nil
	else
		local decoded = json.decode(out)
		local curr = decoded.current
		local hour = decoded.hourly
		local day = decoded.daily

		data.current = {
			dt = curr.dt,
			sunrise = curr.sunrise,
			sunset = curr.sunset,
			temp = curr.temp,
			feels_like = curr.feels_like,
			pressure = curr.pressure,
			humidity = curr.humidity,
			dew_point = curr.dew_point,
			uvi = curr.uvi,
			clouds = curr.clouds,
			visibility = curr.visibility,
			wind_speed = curr.wind_speed,
			wind_deg = curr.wind_deg,
			weather_id = curr.weather[1].id,
			weather_main = curr.weather[1].main,
			weather_desc = curr.weather[1].description:gsub("^%l", string.upper),
			weather_icon = curr.weather[1].icon
		}

		for i = 1, #hour do
			table.insert(data.hourly, {
				dt = hour[i].dt,
				temp = hour[i].temp,
				feels_like = hour[i].feels_like,
				pressure = hour[i].pressure,
				humidity = hour[i].humidity,
				dew_point = hour[i].dew_point,
				uvi = hour[i].uvi,
				clouds = hour[i].clouds,
				visibility = hour[i].visibility,
				wind_speed = hour[i].wind_speed,
				wind_deg = hour[i].wind_deg,
				wind_gust = hour[i].wind_gust,
				weather_id = hour[i].weather[1].id,
				weather_main = hour[i].weather[1].main,
				weather_desc = hour[i].weather[1].description:gsub("^%l", string.upper),
				weather_icon = hour[i].weather[1].icon
			})
		end

		for i = 1, #day do
			table.insert(data.daily, {
				dt = day[i].dt,
				sunrise = day[i].sunrise,
				sunset = day[i].sunset,
				moonrise = day[i].moonrise,
				moonset = day[i].moonset,
				moon_phase = day[i].moon_phase,
				temp_day = day[i].temp.day,
				temp_night = day[i].temp.night,
				temp_eve = day[i].temp.eve,
				temp_morn = day[i].temp.morn,
				temp_min = day[i].temp.min,
				temp_max = day[i].temp.max,
				feels_like_day = day[i].feels_like.day,
				feels_like_night = day[i].feels_like.night,
				feels_like_eve = day[i].feels_like.eve,
				feels_like_morn = day[i].feels_like.morn,
				pressure = day[i].pressure,
				humidity = day[i].humidity,
				dew_point = day[i].dew_point,
				wind_speed = day[i].wind_speed,
				wind_deg = day[i].wind_deg,
				wind_gust = day[i].wind_gust,
				clouds = day[i].clouds,
				pop = day[i].pop,
				uvi = day[i].uvi,
				weather_id = day[i].weather[1].id,
				weather_main = day[i].weather[1].main,
				weather_desc = day[i].weather[1].description:gsub("^%l", string.upper),
				weather_icon = day[i].weather[1].icon
			})
		end
	end

	self:emit_signal("weather::data", data)
end

function weather_daemon:set_remote_watch()
	if self.api_key then
		local forecast_cmd = "curl -sf 'https://api.openweathermap.org/data/2.5/onecall?" ..
			"lat=" .. self.lat ..
			"&lon=" .. self.lon ..
			"&appid=" .. self.api_key ..
			"&units=" .. self.units ..
			"&exclude=minutely'"

		helpers.util.remote_watch(forecast_cmd, self.update_interval, self.tmp_file, function(out)
			self:extract_data(out)
		end)
	end
end

local function new()
	local ret = gears.object {}
	gears.table.crush(ret, weather_daemon, true)

	ret.update_interval = 1200
	ret.tmp_file = "/tmp/awesomewm_weather.json"

	ret.lat = user.coords and user.coords[1] or 0
	ret.lon = user.coords and user.coords[2] or 0
	ret.units = user.OWM_units or "metric"
	ret.api_key = user.OWM_key or nil

	ret:set_remote_watch()

	return ret
end

if not instance then
	instance = new()
end

return instance
