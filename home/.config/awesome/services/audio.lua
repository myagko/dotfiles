local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")

local audio = {}

function audio:get_sink_data(sink)
	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-volume " .. sink, function(stdout)
		self.vol_value = tonumber(stdout:match("/%s+(%d+)"))
		self:emit_signal("sink::value", sink, self.vol_value)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-sink-mute " .. sink, function(stdout)
		self.vol_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("sink::mute", sink, self.vol_mute)
	end)
end

function audio:set_sink_value(sink, value)
	awful.spawn("pactl set-sink-volume " .. sink .. " " .. tostring(value) .. "%", false)
end

function audio:toggle_sink_mute(sink)
	awful.spawn("pactl set-sink-mute " .. sink .. " toggle", false)
end

function audio:get_source_data(source)
	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-volume " .. source, function(stdout)
		self.mic_value = tonumber(stdout:match("/%s+(%d+)"))
		self:emit_signal("source::value", source, self.mic_value)
	end)

	awful.spawn.easy_async_with_shell("LANG=C pactl get-source-mute " .. source, function(stdout)
		self.mic_mute = stdout:match("%s+(%w+)") == "yes"
		self:emit_signal("source::mute", source, self.mic_mute)
	end)
end

function audio:set_source_value(source, value)
	awful.spawn("pactl set-source-volume " .. source .. " " .. tostring(value) .. "%", false)
end

function audio:toggle_source_mute(source)
	awful.spawn("pactl set-source-mute " .. source .. " toggle", false)
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, audio, true)

	ret:get_sink_data("@DEFAULT_SINK@")
	ret:get_source_data("@DEFAULT_SOURCE@")

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return {
	get_default = get_default
}
