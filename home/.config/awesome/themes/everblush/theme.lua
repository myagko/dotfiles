local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local gshape = require("gears.shape")
local gcolor = require("gears.color")
local dpi = beautiful.xresources.apply_dpi

local theme_name = "everblush"
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
	menu = "",
	trash = "",
	calendar = "",
	wifi = "",
	bluetooth = "",
	search = "",
	home = "",
	image = "",
	sun = "",
	moon = "",
	wind = "",
	thermometer = "",
	droplet = "",
	no_cloud = "",
	cloud = "",
	rain = "",
	shower_rain = "",
	thunder = "",
	snow = "",
	mist = ""
}

theme.red = "#E57474"
theme.green = "#8CCF7E"
theme.yellow = "#E5C76B"
theme.blue = "#67B0E8"
theme.magenta = "#C47FD5"
theme.cyan = "#6CBFBF"
theme.orange = "#E6A068"
theme.bg = "#141B1E"
theme.bg_alt = "#21282B"
theme.bg_urg = "#3F4547"
theme.fg_alt = "#676B6D"
theme.fg = "#DADADA"
theme.ac = theme.cyan

theme.rounded = false

theme.border_color = theme.bg_urg
theme.sep_width = dpi(1)
theme.border_width = dpi(1)
theme.useless_gap = dpi(3)

theme.bg_normal = theme.bg
theme.fg_normal = theme.fg
theme.border_color_normal = theme.bg_urg
theme.border_color_active = theme.ac

theme.titlebar_bg_normal = theme.bg
theme.titlebar_bg_focus = theme.bg
theme.titlebar_bg_urgent = theme.bg
theme.titlebar_fg_normal = theme.fg_alt
theme.titlebar_fg_focus = theme.fg
theme.titlebar_fg_urgent = theme.red

theme.tooltip_bg = theme.bg
theme.tooltip_fg = theme.bg
theme.tooltip_border_width = theme.border_width
theme.tooltip_border_color = theme.border_color

theme.snap_border_width = theme.border_width*4
theme.snap_bg = theme.ac
theme.snapper_gap = dpi(6)
theme.snap_shape = gshape.rectangle

theme.notification_margins = dpi(30)
theme.notification_spacing = dpi(10)
theme.notification_timeout = 5

theme.menu_submenu = theme.text_icons.arrow_right .. " "
theme.menu_bg_normal = theme.bg
theme.menu_fg_normal = theme.fg
theme.menu_bg_focus = theme.ac
theme.menu_fg_focus = theme.bg
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.layout_floating = gcolor.recolor_image(icons_path .. "layout_floating.png", theme.fg)
theme.layout_tile = gcolor.recolor_image(icons_path .. "layout_tile.png", theme.fg)

theme.systray_icon_spacing = dpi(6)
theme.bg_systray = theme.bg_alt

return theme
