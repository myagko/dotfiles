local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local gfilesytem = require("gears.filesystem")
local beautiful = require("beautiful")
local helpers = require("helpers")
local user = require("user")

local wallpaper = {}

function wallpaper:set(new_image)
	if not new_image then return end
	self.widget = {
		widget = wibox.widget.imagebox,
		resize = true,
		valign = "center",
		halign = "center",
		horizontal_fit_policy = "cover",
		vertical_fit_policy = "cover",
		image = new_image
	}
	self:repaint()
	user.wallpaper = new_image
	helpers.table_to_file(gfilesytem.get_configuration_dir() .. "/user.lua", user)
end

return function(s)
	local ret = awful.wallpaper {
		screen = s,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.background_alt
		}
	}

	gtable.crush(ret, wallpaper, true)
	return ret
end
