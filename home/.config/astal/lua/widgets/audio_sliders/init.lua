local astal = require("astal")
local bind = astal.bind
local AstalWp = astal.require("AstalWp")
local Widget = require("astal.gtk3").Widget
local text_icons = require("lua.text_icons")

local WpAudio = AstalWp.get_default():get_audio()
local speaker = WpAudio:get_default_speaker()
local microphone = WpAudio:get_default_microphone()

return function()
	return Widget.Box {
		class_name = "audio-sliders",
		vertical = true,
		spacing = 8,
		Widget.Box {
			class_name = "speaker",
			spacing = 10,
			hexpand = true,
			Widget.Button {
				class_name = bind(speaker, "mute"):as(function(m)
					return "mute-button" .. (m and " muted" or "")
				end),
				on_clicked = function()
					speaker:set_mute(not speaker:get_mute())
				end,
				Widget.Label {
					label = bind(speaker, "mute"):as(function(m)
						return m and text_icons.vol_off or text_icons.vol_on
					end)
				}
			},
			Widget.Slider {
				class_name = bind(speaker, "mute"):as(function(m)
					return "volume-slider" .. (m and " muted" or "")
				end),
				hexpand = true,
				value = bind(speaker, "volume"),
				on_dragged = function(self)
					speaker:set_volume(self.value)
				end
			},
			Widget.Label {
				class_name = "volume-value",
				width_chars = 4,
				label = bind(speaker, "volume"):as(function(v)
					return tostring(math.floor(v * 100)) .. "%"
				end)
			}
		},
		Widget.Box {
			class_name = "microphone",
			spacing = 10,
			hexpand = true,
			Widget.Button {
				class_name = bind(microphone, "mute"):as(function(m)
					return "mute-button" .. (m and " muted" or "")
				end),
				on_clicked = function()
					microphone:set_mute(not microphone:get_mute())
				end,
				Widget.Label {
					label = bind(microphone, "mute"):as(function(m)
						return m and text_icons.mic_off or text_icons.mic_on
					end)
				}
			},
			Widget.Slider {
				class_name = bind(microphone, "mute"):as(function(m)
					return "volume-slider" .. (m and " muted" or "")
				end),
				hexpand = true,
				value = bind(microphone, "volume"),
				on_dragged = function(self)
					microphone:set_volume(self.value)
				end
			},
			Widget.Label {
				class_name = "volume-value",
				width_chars = 4,
				label = bind(microphone, "volume"):as(function(v)
					return tostring(math.floor(v * 100)) .. "%"
				end)
			}
		}
	}
end
