local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local gfilesystem = require("gears.filesystem")
local beautiful = require("beautiful")
local inspect = require("external.inspect")
local user = require("user")

local wallpaper = {}

function wallpaper:set(new_image, is_first_set)
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

	if not is_first_set then
		user.wallpaper = new_image
		local inspected = assert(inspect(user, { indent = "\t" }))
		local wfile = assert(io.open(gfilesystem.get_configuration_dir() .. "/user.lua", "w"))
		wfile:write("return " .. inspected)
		wfile:close()
	end
end

return function(s)
	local ret = awful.wallpaper {
		screen = s,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.bg_alt
		}
	}

	gtable.crush(ret, wallpaper, true)
	return ret
end
