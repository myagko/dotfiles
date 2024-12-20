local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")

local sep = {}

function sep:set_color(color)
	self:get_children_by_id("sep")[1].bg = color
end

local function new(args)
	args = args or {}
	local widget

	widget = wibox.widget {
		widget = wibox.container.margin,
		margins = args.margins or 0,
		{
			id = "sep",
			widget = wibox.container.background,
			bg = args.color or beautiful.background_urgent or "#ffffff"
		}
	}

	gtable.crush(widget, sep, true)

	local wp = widget._private
	wp.dir = args.dir or "h"
	wp.size = args.size or 1

	if wp.dir == "v" then
		widget:get_children_by_id("sep")[1].forced_width = wp.size
	elseif wp.dir == "h" then
		widget:get_children_by_id("sep")[1].forced_height = wp.size
	end

	return widget
end

return setmetatable(sep, {
	__call = function(_, ...)
		return new(...)
	end
})
