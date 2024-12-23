local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local gshape = require("gears.shape")
local gcolor = require("gears.color")
local dpi = beautiful.xresources.apply_dpi

local theme_name = "haven"
local theme_path = gfilesystem.get_configuration_dir() .. "/themes/" .. theme_name .. "/"
local icons_path = theme_path .. "icons/"

local theme = {}

theme.font_name = "JetBrains Mono NL Slashed"
theme.font_h0 = theme.font_name .. " " .. tostring(dpi(10))
theme.font_h1 = theme.font_name .. " " .. tostring(dpi(13))
theme.font_h2 = theme.font_name .. " " .. tostring(dpi(19))
theme.font_h3 = theme.font_name .. " " .. tostring(dpi(26))
theme.font = theme.font_h1

theme.text_icons = {
	eye_on = "",
	eye_off = "",
	check_on = "",
	check_off = "",
	switch_on = "",
	switch_off = "",
	vol_on = "",
	vol_off = "",
	mic_on = "",
	mic_off = "",
	bell_on = "",
	bell_off = "",
	lock_on = "",
	lock_off = "",
	arrow_left = "",
	arrow_right = "",
	arrow_up = "",
	arrow_down = "",
	dash = "",
	cross = "",
	check = "",
	stretch = "",
	shrink = "",
	gear = "",
	sliders = "",
	wait = "",
	poweroff = "",
	reboot = "",
	exit = "",
	apps = "",
	trash = "",
	calendar = "",
	wifi = "",
	bluetooth = "",
	search = "",
	sun = "",
	moon = "",
	wind = "",
	droplet = "",
	no_cloud = "",
	cloud = "",
	rain = "",
	shower_rain = "",
	thunder = "",
	snow = "",
	mist = ""
}

theme.red = "#EA6962"
theme.green = "#A9B665"
theme.yellow = "#D8A657"
theme.blue = "#7DAEA3"
theme.magenta = "#D3869B"
theme.cyan = "#89B482"
theme.orange = "#E78A4E"
theme.background = "#282828"
theme.background_alt = "#32302F"
theme.background_urgent = "#45403D"
theme.foreground_alt = "#7C6F64"
theme.foreground = "#DDC7A1"

theme.accent = theme.yellow
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

theme.sep_width = dpi(1)
theme.border_width = dpi(1)
theme.useless_gap = dpi(3)

theme.snap_border_width = theme.border_width*4
theme.snap_bg = theme.accent
theme.snapper_gap = dpi(6)
theme.snap_shape = gshape.rectangle

theme.notification_spacing = theme.useless_gap*4
theme.notification_position = "top_right"
theme.notification_timeout = 5
theme.notification_max_width = dpi(380)
theme.notification_min_width = dpi(300)
theme.notification_max_height = dpi(150)
theme.notification_min_height = dpi(50)
theme.notification_icon_bell = gcolor.recolor_image(icons_path .. "bell.png", theme.foreground)
theme.notification_icon_camera = gcolor.recolor_image(icons_path .. "camera.png", theme.foreground)
theme.notification_icon_alert = gcolor.recolor_image(icons_path .. "alert.png", theme.red)

theme.menu_submenu = theme.text_icons.arrow_right .. " "
theme.menu_bg_normal = theme.background
theme.menu_fg_normal = theme.foreground
theme.menu_bg_focus = theme.accent
theme.menu_fg_focus = theme.background
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.layout_floating = gcolor.recolor_image(icons_path .. "layout_floating.png", theme.foreground)
theme.layout_tile = gcolor.recolor_image(icons_path .. "layout_tile.png", theme.foreground)

theme.systray_icon_spacing = dpi(6)
theme.bg_systray = theme.background_alt

return theme
