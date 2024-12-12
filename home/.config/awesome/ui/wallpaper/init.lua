local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")

local wallpaper = {}

function wallpaper:set_image(new_image)
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
end

function wallpaper:set_tile(new_tile, tile_size)
	if not new_tile then return end
	self.widget = {
		widget = wibox.container.tile,
		{
			widget = wibox.widget.imagebox,
			scaling_quality = "nearest",
			resize = tile_size and true or false,
			forced_width = tile_size,
			forced_height = tile_size,
			image = new_tile
		}
	}
	self:repaint()
end

function wallpaper:set_color(new_color)
	new_color = new_color or beautiful.background_alt
	self.widget = {
		widget = wibox.container.background,
		bg = new_color
	}
	self:repaint()
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
