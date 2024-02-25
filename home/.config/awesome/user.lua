local M = {}
M.theme = "placid"

M.terminal = "alacritty"
M.webbrowser = "firefox"
M.filemanager = "nemo"

M.shotdir = "~/Screenshots/"

M.OWM_key = "e434b5435a979de6e155570590bee89b"
M.coords = { 55.0082423, 82.9387996 }

--M.pa_sink = "1"
--M.pa_source = "1"

M.autostart = {
	"xrandr --output DisplayPort-2 --mode 1920x1080 --rate 165.00",
	"picom",
}

return M
