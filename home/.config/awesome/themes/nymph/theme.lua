local gears = require("gears")

local theme_name = "nymph"
local theme_path = "~/.config/awesome/themes/" .. theme_name .. "/"
local icons_path = theme_path .. "icons/"

local theme = {}

theme.wallpaper = theme_path .. "wall.png"

theme.font_name = "Iosevka"
theme.font_size = 13.5
theme.font = theme.font_name .. " " .. tostring(theme.font_size)

theme.useless_gap = 3
theme.border_width = 2
theme.sep_width = 2

theme.cyan = "#89B7B0"
theme.red = "#BC7171"
theme.yellow = "#D5BE82"
theme.green = "#9FBC85"
theme.blue = "#7C9BB4"
theme.magenta = "#A883A2"
theme.orange = "#D49776"
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

theme.snap_border_width = theme.border_width*4
theme.snap_bg = theme.accent
theme.snapper_gap = 6
theme.snap_shape = gears.shape.rectangle

theme.notification_spacing = theme.useless_gap*4.5

theme.icon_bell = icons_path .. "bell.png"
theme.icon_bell_off = icons_path .. "bell_off.png"
theme.icon_photo = icons_path .. "camera.png"
theme.icon_alert = icons_path .. "alert.png"

theme.menu_submenu = ">  "
theme.menu_height = 32
theme.menu_width  = 150
theme.menu_bg_normal = theme.background
theme.menu_fg_normal = theme.foreground
theme.menu_bg_focus = theme.accent
theme.menu_fg_focus = theme.background
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.systray_icon_spacing = 6
theme.bg_systray = theme.background_alt

theme.icon_theme = nil

return theme
