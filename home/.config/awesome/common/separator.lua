local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")

local separator = {}

function separator:set_color(color)
	self:get_children_by_id("container")[1]:set_bg(color)
end

function separator:set_size(size)
	local wp = self._private
	if wp.dir == "v" then
		self:get_children_by_id("container")[1]:set_forced_width(size)
	elseif wp.dir == "h" then
		self:get_children_by_id("container")[1]:set_forced_height(size)
	end
end

local function new(args)
	args = args or {}
	local widget

	widget = wibox.widget {
		widget = wibox.container.margin,
		margins = args.margins or 0,
		{
			id = "container",
			widget = wibox.container.background,
			bg = args.color or beautiful.bg_urg or "#ffffff"
		}
	}

	gtable.crush(widget, separator, true)

	local wp = widget._private
	wp.vertical = args.vertical
	wp.size = args.size or 1

	if wp.vertical then
		widget:get_children_by_id("container")[1]:set_forced_height(wp.size)
	else
		widget:get_children_by_id("container")[1]:set_forced_width(wp.size)
	end

	return widget
end

return setmetatable(separator, {
	__call = function(_, ...)
		return new(...)
	end
})
