local awful = require("awful")
local gears = require("gears")

local util = {}

function util.remote_watch(command, interval, output_file, callback)
	local run_the_thing = function()
		awful.spawn.easy_async_with_shell(command .. " | tee " .. output_file, function(out) callback(out) end)
	end

	local timer
	timer = gears.timer {
		timeout = interval,
		call_now = true,
		autostart = true,
		single_shot = false,
		callback = function()
			awful.spawn.easy_async_with_shell("date -r " .. output_file .. " +%s", function(last_update, _, _, exitcode)
				if exitcode == 1 then
					run_the_thing()
					return
				end

				local diff = os.time() - tonumber(last_update)
				if diff >= interval then
					run_the_thing()
				else
					awful.spawn.easy_async_with_shell("cat " .. output_file, function(out) callback(out) end)
					timer:stop()
					gears.timer.start_new(interval - diff, function()
						run_the_thing()
						timer:again()
					end)
				end
			end)
		end
	}
end

function util.spawn_once(cmd_arr)
	for _, cmd in ipairs(cmd_arr) do
		local findme = cmd
		local firstspace = cmd:find(" ")
		if firstspace then
			findme = cmd:sub(0, firstspace - 1)
		end
		awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
	end
end

function util.to_direction(deg)
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

function util.hPa_to_mmHg(x)
	return x*0.75
end

return util
