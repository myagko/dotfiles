-- nedded for creating new themes,
-- it recolors icon pngs for selected theme
-- with single color so i don't have to do it by myself with krita or gimp

-- usage: $ awesome-client 'require "themes.recolor_icons" ()'

local awful = require("awful")
local beautiful = require("beautiful")

local function recolor_image(image, color)
	awful.spawn.with_shell("convert " .. image .. " -alpha extract -background '" .. color .. "' -alpha shape -define png:color-type=6 " .. image)
end

return function()
	recolor_image(beautiful.notification_icon_bell, beautiful.foreground)
	recolor_image(beautiful.notification_icon_camera, beautiful.foreground)
	recolor_image(beautiful.notification_icon_alert, beautiful.red)
	recolor_image(beautiful.layout_floating, beautiful.foreground)
	recolor_image(beautiful.layout_tile, beautiful.foreground)
end

