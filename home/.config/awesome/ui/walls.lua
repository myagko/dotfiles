local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Wall = {}

function Wall:create(s)
	return awful.wallpaper {
		screen = s,
			widget = {
			widget = wibox.widget.imagebox,
			resize = true,
			valign = "center",
			halign = "center",
			horizontal_fit_policy = "cover",
			vertical_fit_policy = "cover",
			image = beautiful.wallpaper
		}
	}
end

return Wall
