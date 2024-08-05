local beautiful = require("beautiful")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi

local theme_name = "placid"
local theme_path = "~/.config/awesome/themes/" .. theme_name .. "/"
local icons_path = theme_path .. "icons/"
local walls_path = theme_path .. "walls/"

local theme = {}

theme.wallpaper = walls_path .. "01.png"

theme.font_name = "Iosevka"
theme.font_size = dpi(14)
theme.font = theme.font_name .. " " .. tostring(theme.font_size)

theme.red = "#CE4A3B"
theme.green = "#1AB15A"
theme.yellow = "#DDAF34"
theme.blue = "#286DC1"
theme.magenta = "#A756B1"
theme.cyan = "#2FADC1"
theme.orange = "#D2782C"

theme.background = "#1A1A1A"
theme.background_alt = "#262626"
theme.background_urgent = "#383838"
theme.foreground_alt = "#535353"
theme.foreground = "#CCCCCC"

theme.accent = theme.cyan
theme.bg_normal = theme.background
theme.fg_normal = theme.foreground
theme.border_color = theme.background_urgent

theme.titlebar_bg_normal = theme.background
theme.titlebar_bg_focus = theme.background
theme.titlebar_bg_urgent = theme.background

theme.tooltip_bg = theme.background
theme.tooltip_fg = theme.foreground
theme.tooltip_border_width = theme.border_width
theme.tooltip_border_color = theme.border_color

theme.useless_gap = dpi(3)
theme.border_width = dpi(1)
theme.comp_border_width = dpi(1)
theme.sep_width = dpi(1)

theme.snap_border_width = theme.border_width*4
theme.snap_bg = theme.accent
theme.snapper_gap = dpi(6)
theme.snap_shape = gears.shape.rectangle

theme.notification_spacing = theme.useless_gap*4.5
theme.notification_position = "top_right"
theme.notification_timeout = 5
theme.notification_max_width = dpi(380)
theme.notification_min_width = dpi(300)
theme.notification_max_height = dpi(150)
theme.notification_min_height = dpi(50)
theme.notification_icon_bell = icons_path .. "bell.png"
theme.notification_icon_camera = icons_path .. "camera.png"
theme.notification_icon_alert = icons_path .. "alert.png"

theme.menu_submenu = ">  "
theme.menu_height = dpi(32)
theme.menu_width = dpi(150)
theme.menu_bg_normal = theme.background
theme.menu_fg_normal = theme.foreground
theme.menu_bg_focus = theme.accent
theme.menu_fg_focus = theme.background
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.systray_icon_spacing = dpi(6)
theme.bg_systray = theme.background_alt

theme.text_icons = {
	poweroff = "",
	reboot = "",
	exit = "",
	arrow_left = "",
	arrow_right = "",
	arrow_up = "",
	arrow_down = "",
	cross = "",
	switch_on = "",
	switch_off = "",
	gear = "",
	calendar = "",
	wifi_on = "",
	wifi_off = "",
	bluetooth_on = "",
	bluetooth_off = "",
	vol_on = "",
	vol_off = "",
	mic_on = "",
	mic_off = "",
	bell_on = "",
	bell_off = "",
	lock = "",
	unlock = "",
	apps = "",
	trash = "",
	check_on = "",
	check_off = "",
	visible = "",
	invisible = "",
	wait = "",
	sun = "",
	moon = "",
	cloud = "",
	rain = "",
	shower_rain = "",
	thunder = "",
	snow = "",
	mist = ""
}


return theme
