local awful = require("awful")
local User = require("user")
local sink = User.pa_sink or "@DEFAULT_SINK@"
local source = User.pa_source or "@DEFAULT_SOURCE@"

local Pulse = {}

function Pulse:vol_get()
	awful.spawn.easy_async_with_shell("pactl get-sink-volume " .. sink, function(stdout)
		local val = stdout:match("/%s+(%d+)")
		awesome.emit_signal("audio:vol_val", val)
	end)
	awful.spawn.easy_async_with_shell("pactl get-sink-mute " .. sink, function(stdout)
		local mut = stdout:match("%s+(%w+)")
		local mute
		if mut == "yes" then
			mute = true
		else
			mute = false
		end
		awesome.emit_signal("audio:vol_mute", mute)
	end)
end

function Pulse:vol_set_val(value)
	awful.spawn("pactl set-sink-volume " .. sink .. " " .. tostring(value) .. "%", false)
end

function Pulse:vol_set_mut()
	awful.spawn("pactl set-sink-mute " .. sink .. " toggle", false)
end

function Pulse:mic_get()
	awful.spawn.easy_async_with_shell("pactl get-source-volume " .. source, function(stdout)
		local val = stdout:match("/%s+(%d+)")
		awesome.emit_signal("audio:mic_val", val)
	end)
	awful.spawn.easy_async_with_shell("pactl get-source-mute " .. source, function(stdout)
		local mut = stdout:match("%s+(%w+)")
		local mute
		if mut == "yes" then
			mute = true
		else
			mute = false
		end
		awesome.emit_signal("audio:mic_mute", mute)
	end)
end

function Pulse:mic_set_val(value)
	awful.spawn("pactl set-source-volume " .. source .. " " .. tostring(value) .. "%", false)
end

function Pulse:mic_set_mut()
	awful.spawn("pactl set-source-mute " .. source .. " toggle", false)
end

return Pulse
