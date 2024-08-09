local awful = require("awful")
local wibox = require("wibox")

local walls = {}

function walls.create(s)
	return awful.wallpaper {
		screen = s,
		widget = {
			widget = wibox.widget.imagebox,
			resize = true,
			valign = "center",
			halign = "center",
			horizontal_fit_policy = "cover",
			vertical_fit_policy = "cover"
		},
		set = function(widget, new_wall)
			widget.widget.image = new_wall
			widget:repaint()
		end
	}
end

return walls
