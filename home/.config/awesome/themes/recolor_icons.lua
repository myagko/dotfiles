-- nedded for creating new themes,
-- it recolors icon pngs for selected theme
-- with single color so i don't have to do it by myself with krita or gimp

-- usage: $ awesome-client 'require "themes.recolor_icons"'

local User = require("user")
local helpers = require("helpers")
local beautiful = require("beautiful")
local icons_path = "~/.config/awesome/themes/" .. User.theme .. "/icons/"

helpers:recolor_image(icons_path .. "bell.png")
helpers:recolor_image(icons_path .. "bell_off.png")
helpers:recolor_image(icons_path .. "camera.png")
helpers:recolor_image(icons_path .. "alert.png", beautiful.red)
