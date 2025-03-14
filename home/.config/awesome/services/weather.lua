local gobject = require("gears.object")
local gtable = require("gears.table")
local widgets = require("widgets")
local json = require("external.json")
local user = require("user")

local weather = {}
local instance = nil

function weather:set_remote_watch()
	local wp = self._private
	local cmd = "curl -sf 'https://api.open-meteo.com/v1/forecast?" ..
		"latitude=" .. self.lat .. "&longitude=" .. self.lon ..
		"&current=temperature_2m,relative_humidity_2m,weather_code,surface_pressure," ..
		"wind_speed_10m,wind_direction_10m,apparent_temperature," ..
		"&hourly=temperature_2m,weather_code" ..
		"&daily=weather_code,temperature_2m_max,temperature_2m_min" ..
		"&wind_speed_unit=ms&forecast_hours=24" ..
		"&timeformat=unixtime&timezone=auto" ..
		(self.imperial_units and "&temperature_unit=fahrenheit" or "") .. "'"

	wp.remote_watch = widgets.remote_watch(cmd, self.interval, self.tmp_file, function(out)
		local data = (out ~= "" and json.decode(out) or nil)
		self:emit_signal("data_received", data)
	end)
end

local function new(args)
	args = args or {}
	local ret = gobject {}
	gtable.crush(ret, weather, true)
	ret._private = {}

	ret.lat = args.lat or 0
	ret.lon = args.lon or 0
	ret.tmp_file = args.tmp_file or "/tmp/awesomewm_weather.json"
	ret.interval = args.interval or 600
	ret.imperial_units = args.weather_imperial_units
	ret:set_remote_watch()

	return ret
end

if not instance then
	instance = new({
		lat = user.weather_location and user.weather_location[1],
		lon = user.weather_location and user.weather_location[2]
	})
end

return instance
