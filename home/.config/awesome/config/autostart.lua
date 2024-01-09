local awful = require("awful")
local User = require("user")

local Bluetooth = require("daemons.bluetooth")
local Wifi = require("daemons.wifi")
local Pulse = require("daemons.pulse")

Pulse:vol_get()
Pulse:mic_get()
Bluetooth:get_status()
Wifi:get_status()

require("daemons.stats")
require("daemons.weather")

if User.autostart then
	for _, command in ipairs(User.autostart) do
		awful.spawn(command)
	end
end
