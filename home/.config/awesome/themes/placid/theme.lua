local gears = require("gears")

local theme_name = "placid"
local theme_path = "~/.config/awesome/themes/" .. theme_name .. "/"
local icons_path = theme_path .. "icons/"

local theme = {}

theme.red = "#CB6F65"
theme.green = "#A7B163"
theme.yellow = "#CCB175"
theme.blue = "#759AA4"
theme.magenta = "#B18293"
theme.cyan = "#86AB9D"
theme.orange = "#D39867"

theme.background = "#1F1F1F"
theme.background_alt = "#292929"
theme.background_urgent = "#393939"
theme.foreground_alt = "#686868"
theme.foreground = "#BBBBBB"

theme.wallpaper = theme_path .. "wall.png"

theme.font_name = "Iosevka"
theme.font_size = 13.5
theme.font = theme.font_name .. " " .. tostring(theme.font_size)

theme.useless_gap = 3
theme.border_width = 2
theme.sep_width = 2

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
theme.menu_width = 150
theme.menu_bg_normal = theme.background
theme.menu_fg_normal = theme.foreground
theme.menu_bg_focus = theme.accent
theme.menu_fg_focus = theme.background
theme.menu_border_width = theme.border_width
theme.menu_border_color = theme.border_color

theme.systray_icon_spacing = 6
theme.bg_systray = theme.background_alt

theme.bar_height = 45
theme.bar_spacing = 7
theme.bar_module_margins = 8

theme.taglist_margins = 8
theme.taglist_item_size = 16

theme.tasklist_margins = 8
theme.tasklist_selection_size = theme.border_width

theme.launcher_rows = 6
theme.launcher_item_size = 55
theme.launcher_width = 290
theme.launcher_margins = 10

theme.powermenu_item_size = 120
theme.powermenu_icon_size = 12.5
theme.powermenu_margins = 10

theme.ctrl_center_margins = 10

theme.notif_list_height = 530
theme.notif_list_width = 450
theme.notif_list_item_height = 120
theme.notif_list_header_height = 50

theme.bluetooth_rows = 8
theme.bluetooth_item_size = 55
theme.bluetooth_width = 400

theme.wifi_rows = 8
theme.wifi_item_size = 55
theme.wifi_width = 400

theme.icon_theme = nil

return theme
