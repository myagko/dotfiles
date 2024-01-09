local M = {}
-- theme
M.theme = "nymph"

-- default apps
M.terminal = "alacritty"
M.webbrowser = "firefox"
M.filemanager = "nemo"

-- screenshot directory
M.shotdir = "~/Screenshots/"

-- open weather map
M.key = "e7704bc895b4a8d2dfd4a29d404285b6"
M.coords = { 55.0082423, 82.9387996 }

-- pulseaudio default sink & source ( $ pactl list sinks/sources )
-- if not specified it would change volume for @DEFAULT_SINK@/@DEFAULT_SOURCE@
-- M.pa_sink = "1" or "alsa_output.pci-0000_0b_00.6.analog-stereo"
-- M.pa_source = "2" or "alsa_output.pci-0000_0b_00.6.analog-stereo"

M.autostart = {
	--"xrandr --output DisplayPort-2 --mode 1920x1080 --rate 165.00",
	"xrandr --output HDMI-A-0 --mode 1920x1080 --rate 144.00",
	"picom",
}

return M
