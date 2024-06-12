local awful = require("awful")
local User = require("user")

local pulse = {
    vol = {},
    mic = {}
}

pulse.vol.sink = User.pa_sink or "@DEFAULT_SINK@"
pulse.mic.source = User.pa_source or "@DEFAULT_SOURCE@"

function pulse.vol:get_value()
    awful.spawn.easy_async_with_shell("pactl get-sink-volume " .. self.sink, function(stdout)
        self.value = stdout:match("/%s+(%d+)")
        awesome.emit_signal("audio:vol_val", tonumber(self.value))
    end)
    awful.spawn.easy_async_with_shell("pactl get-sink-mute " .. self.sink, function(stdout)
        self.mute = stdout:match("%s+(%w+)") == "yes"
        awesome.emit_signal("audio:vol_mute", self.mute)
    end)
end

function pulse.vol:set_value(value)
    awful.spawn("pactl set-sink-volume " .. self.sink .. " " .. tostring(value) .. "%", false)
end

function pulse.vol:toggle_mute()
    awful.spawn("pactl set-sink-mute " .. self.sink .. " toggle", false)
end

function pulse.mic:get_value()
    awful.spawn.easy_async_with_shell("pactl get-source-volume " .. self.source, function(stdout)
        self.value = stdout:match("/%s+(%d+)")
        awesome.emit_signal("audio:mic_val", self.value)
    end)
    awful.spawn.easy_async_with_shell("pactl get-source-mute " .. self.source, function(stdout)
        self.mute = stdout:match("%s+(%w+)") == "yes"
        awesome.emit_signal("audio:mic_mute", self.mute)
    end)
end

function pulse.mic:set_value(value)
    awful.spawn("pactl set-source-volume " .. self.source .. " " .. tostring(value) .. "%", false)
end

function pulse.mic:toggle_mute()
    awful.spawn("pactl set-source-mute " .. self.source .. " toggle", false)
end

function pulse:get_all()
    self.vol:get_value()
    self.mic:get_value()
end

return pulse
