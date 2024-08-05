local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

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
		set = function(self, new_wall)
			self.widget.image = new_wall
			self:repaint()
		end
	}
end

return walls
