local awful = require("awful")
local User = require("user")

local pulse = {
	vol = {},
	mic = {}
}

pulse.vol.sink = User.pa_sink or "@DEFAULT_SINK@"
pulse.mic.source = User.pa_source or "@DEFAULT_SOURCE@"

function pulse.vol:get_value(sink)
	sink = sink or self.sink

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-volume " .. sink, function(stdout)
		self.value = stdout:match("/%s+(%d+)")
		awesome.emit_signal("audio:vol_val", tonumber(self.value))
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-mute " .. sink, function(stdout)
		self.mute = stdout:match("%s+(%w+)") == "yes"
		awesome.emit_signal("audio:vol_mute", self.mute)
	end)
end

function pulse.vol:set_value(value, sink)
	sink = sink or self.sink

	awful.spawn("pactl set-sink-volume " .. sink .. " " .. tostring(value) .. "%", false)
end

function pulse.vol:toggle_mute(sink)
	sink = self.sink

	awful.spawn("pactl set-sink-mute " .. sink .. " toggle", false)
end

function pulse.mic:get_value(source)
	source = source or self.source

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-volume " .. source, function(stdout)
		self.value = stdout:match("/%s+(%d+)")
		awesome.emit_signal("audio:mic_val", self.value)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-mute " .. source, function(stdout)
		self.mute = stdout:match("%s+(%w+)") == "yes"
		awesome.emit_signal("audio:mic_mute", self.mute)
	end)
end

function pulse.mic:set_value(value, source)
	source = source or self.source

	awful.spawn("pactl set-source-volume " .. source .. " " .. tostring(value) .. "%", false)
end

function pulse.mic:toggle_mute(source)
	source = source or self.source

	awful.spawn("pactl set-source-mute " .. source .. " toggle", false)
end

function pulse:get_all()
	self.vol:get_value()
	self.mic:get_value()
end

return pulse
