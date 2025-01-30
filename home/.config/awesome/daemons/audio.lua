local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")

local audio = {}
local instance = nil

function audio:vol_get_value(sink)
	sink = sink or "@DEFAULT_SINK@"

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-volume " .. sink, function(stdout)
		self.vol_value = tonumber(stdout:match("/%s+(%d+)"))
		self:emit_signal("vol::value", self.vol_value, sink)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-mute " .. sink, function(stdout)
		self.vol_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("vol::mute", self.vol_mute, sink)
	end)
end

function audio:vol_set_value(value, sink)
	sink = sink or "@DEFAULT_SINK@"
	awful.spawn("pactl set-sink-volume " .. sink .. " " .. tostring(value) .. "%", false)
end

function audio:vol_toggle_mute(sink)
	sink = sink or "@DEFAULT_SINK@"
	awful.spawn("pactl set-sink-mute " .. sink .. " toggle", false)
end

function audio:mic_get_value(source)
	source = source or "@DEFAULT_SOURCE@"

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-volume " .. source, function(stdout)
		self.mic_value = tonumber(stdout:match("/%s+(%d+)"))
		self:emit_signal("mic::value", self.mic_value, source)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-mute " .. source, function(stdout)
		self.mic_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("mic::mute", self.mic_mute, source)
	end)
end

function audio:mic_set_value(value, source)
	source = source or "@DEFAULT_SOURCE@"
	awful.spawn("pactl set-source-volume " .. source .. " " .. tostring(value) .. "%", false)
end

function audio:mic_toggle_mute(source)
	source = source or "@DEFAULT_SOURCE@"
	awful.spawn("pactl set-source-mute " .. source .. " toggle", false)
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, audio, true)

	ret:vol_get_value()
	ret:mic_get_value()

	return ret
end

if not instance then
	instance = new()
end

return instance
