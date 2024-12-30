local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local widgets = require("widgets")
local dpi = beautiful.xresources.apply_dpi
local weather_applet = require("ui.weather_applet")

local day_info = {}
local instance = nil

function day_info:open()
	if self.state then return end
	self.state = true
	self.popup_widget.placement = function(d)
		awful.placement.bottom_right(d, {
			honor_workarea = true,
			margins = beautiful.useless_gap*2
		})
	end
	self.popup_widget.visible = true
	self.calendar:set_current_date()
	self:emit_signal("state", self.state)
end

function day_info:close()
	if not self.state then return end
	self.state = false
	self.popup_widget.visible = false
	self:emit_signal("state", self.state)
end

function day_info:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, day_info, true)

	ret.calendar = widgets.calendar {
		sun_start = false
	}

	ret.main_widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(10),
		weather_applet.main_widget,
		ret.calendar
	}

	ret.popup_widget = awful.popup {
		visible = false,
		ontop = true,
		screen = screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		widget = {
			widget = wibox.container.margin,
			margins = dpi(20),
			ret.main_widget
		}
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
