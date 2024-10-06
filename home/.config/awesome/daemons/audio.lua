local awful = require("awful")
local gears = require("gears")

local audio = {}
local instance = nil

function audio:vol_get_value(sink)
	sink = sink or self.sink

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-volume " .. sink, function(stdout)
		self.vol_value = tonumber(stdout:match("/%s+(%d+)"))
		self:emit_signal("audio:vol_val", self.vol_value)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-mute " .. sink, function(stdout)
		self.vol_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("audio:vol_mute", self.vol_mute)
	end)
end

function audio:vol_set_value(value, sink)
	sink = sink or self.sink

	awful.spawn("pactl set-sink-volume " .. sink .. " " .. tostring(value) .. "%", false)
end

function audio:vol_toggle_mute(sink)
	sink = self.sink

	awful.spawn("pactl set-sink-mute " .. sink .. " toggle", false)
end

function audio:mic_get_value(source)
	source = source or self.source

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-volume " .. source, function(stdout)
		self.mic_value = tonumber(stdout:match("/%s+(%d+)"))
		self:emit_signal("audio:mic_val", self.mic_value)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-mute " .. source, function(stdout)
		self.mic_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("audio:mic_mute", self.mic_mute)
	end)
end

function audio:mic_set_value(value, source)
	source = source or self.source

	awful.spawn("pactl set-source-volume " .. source .. " " .. tostring(value) .. "%", false)
end

function audio:mic_toggle_mute(source)
	source = source or self.source

	awful.spawn("pactl set-source-mute " .. source .. " toggle", false)
end

local function new()
	local ret = gears.object {}
	gears.table.crush(ret, audio, true)

	ret.sink = "@DEFAULT_SINK@"
	ret.source = "@DEFAULT_SOURCE@"

	ret:vol_get_value()
	ret:mic_get_value()

	return ret
end

if not instance then
	instance = new()
end

return instance
