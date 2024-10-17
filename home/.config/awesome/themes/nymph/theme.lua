local beautiful = require("beautiful")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi

local theme_name = "nymph"
local theme_path = "~/.config/awesome/themes/" .. theme_name .. "/"
local icons_path = theme_path .. "icons/"

local theme = {}

theme.ui_top_layout = false

theme.font_name = "JetBrains Mono Slashed"
theme.font_h0 = theme.font_name .. " " .. tostring(dpi(9))
theme.font_h1 = theme.font_name .. " " .. tostring(dpi(13))
theme.font_h2 = theme.font_name .. " " .. tostring(dpi(19))
theme.font_h3 = theme.font_name .. " " .. tostring(dpi(26))
theme.font = theme.font_h1

theme.text_icons = {
	-- ui
	visible = "",
	invisible = "",
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
	lock = "",
	unlock = "",
	arrow_left = "",
	arrow_right = "",
	arrow_up = "",
	arrow_down = "",
	cross = "",
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

	-- weather
	sun = "",
	moon = "",
	cloud = "",
	rain = "",
	shower_rain = "",
	thunder = "",
	snow = "",
	mist = ""
}

theme.red = "#BC7171"
theme.green = "#9FBC85"
theme.yellow = "#D5BE82"
theme.blue = "#7C9BB4"
theme.magenta = "#A883A2"
theme.cyan = "#89B7B0"
theme.orange = "#C99577"
theme.background = "#1A2023"
theme.background_alt = "#252B2E"
theme.background_urgent = "#373D40"
theme.foreground_alt = "#5B6265"
theme.foreground = "#BCC4C9"

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

theme.sep_width = dpi(1)
theme.border_width = dpi(1)
theme.useless_gap = dpi(3)

theme.snap_border_width = theme.border_width*4
theme.snap_bg = theme.accent
theme.snapper_gap = dpi(6)
theme.snap_shape = gears.shape.rectangle

theme.notification_spacing = theme.useless_gap*4
theme.notification_position = "top_right"
theme.notification_timeout = 5
theme.notification_max_width = dpi(380)
theme.notification_min_width = dpi(300)
theme.notification_max_height = dpi(150)
theme.notification_min_height = dpi(50)
theme.notification_icon_bell = icons_path .. "bell.png"
theme.notification_icon_camera = icons_path .. "camera.png"
theme.notification_icon_alert = icons_path .. "alert.png"

theme.menu_submenu = theme.text_icons.arrow_right .. " "
theme.menu_height = dpi(32)
theme.menu_width = dpi(150)
theme.menu_bg_normal = theme.background
theme.menu_fg_normal = theme.foreground
theme.menu_bg_focus = theme.accent
theme.menu_fg_focus = theme.background
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.layout_floating = icons_path .. "layout_floating.png"
theme.layout_tile = icons_path .. "layout_tile.png"

theme.systray_icon_spacing = dpi(6)
theme.bg_systray = theme.background_alt

theme.awesome_icon = beautiful.theme_assets.awesome_icon(32, theme.accent, theme.background)

return theme
