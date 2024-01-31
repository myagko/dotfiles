local M = {}
-- theme
-- variants: nymph, satyr
M.theme = "satyr"

-- default apps
M.terminal = "alacritty"
M.webbrowser = "firefox"
M.filemanager = "nemo"

-- screenshot directory (with "/" on the end)
M.shotdir = "~/Screenshots/"

-- open weather map
M.OWM_key = "e434b5435a979de6e155570590bee89b"
M.coords = { 55.0082423, 82.9387996 }

-- pulseaudio default sink & source ( $ pactl list sinks/sources )
-- if not specified it would change volume for @DEFAULT_SINK@/@DEFAULT_SOURCE@
-- M.pa_sink = "1" or "alsa_output.pci-0000_0b_00.6.analog-stereo"
-- M.pa_source = "2" or "alsa_output.pci-0000_0b_00.6.analog-stereo"

-- run this on EVERY WM restart
M.autostart = {
	"xrandr --output DisplayPort-2 --mode 1920x1080 --rate 165.00",
	"picom",
}

return M
