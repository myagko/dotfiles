local gobject = require("gears.object")
local gtable = require("gears.table")
local widgets = require("widgets")
local json = require("modules.json")
local user = require("user")

local weather_daemon = {}
local instance = nil

function weather_daemon:set_remote_watch(args)
	args = args or {}
	local wp = self._private
	local lat = args.lat or 0
	local lon = args.lon or 0
	local tmp_file = args.tmp_file or "/tmp/awesomewm_weather.json"
	local interval = args.interval or 900
	local imperial_units = args.imperial_units or false
	local cmd = "curl -sf 'https://api.open-meteo.com/v1/forecast?" ..
		"latitude=" .. lat .. "&longitude=" .. lon ..
		"&current=temperature_2m,relative_humidity_2m,weather_code,surface_pressure," ..
		"wind_speed_10m,wind_direction_10m,apparent_temperature," ..
		"&hourly=temperature_2m,weather_code" ..
		"&daily=weather_code,temperature_2m_max,temperature_2m_min" ..
		"&wind_speed_unit=ms&forecast_hours=24" ..
		"&timeformat=unixtime&timezone=auto" ..
		(imperial_units and "&temperature_unit=fahrenheit" or "") .. "'"

	wp.remote_watch = widgets.remote_watch(cmd, interval, tmp_file, function(out)
		local data = (out ~= "" and json.decode(out) or nil)
		self:emit_signal("data_received", data)
	end)
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, weather_daemon, true)
	ret._private = {}

	ret:set_remote_watch({
		lat = user.coords and user.coords[1],
		lon = user.coords and user.coords[2],
		tmp_file = user.tmp_file,
		imperial_units = user.imperial_units
	})

	return ret
end

if not instance then
	instance = new()
end

return instance
