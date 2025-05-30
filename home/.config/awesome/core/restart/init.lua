local gtimer = require("gears.timer")
local capi = { awesome = awesome }

capi.awesome.connect_signal("request::restart", function()
	gtimer.delayed_call(function()
		capi.awesome.restart()
	end)
end)
