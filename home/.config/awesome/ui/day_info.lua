local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local dpi = beautiful.xresources.apply_dpi
local weather_applet = require("ui.weather")
local calendar = require("ui.calendar")

local day_info = {}
local instance = nil

function day_info:open()
	if self.state then return end
	self.state = true
	self.popup_widget.placement = function(d)
		if beautiful.ui_top_layout then
			awful.placement.top_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap*2
			})
		else
			awful.placement.bottom_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap*2
			})
		end
	end
	self.popup_widget.visible = true
	self:emit_signal("state", self.state)
	calendar:set(os.date("*t"))
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
	local ret = gears.object {}
	gears.table.crush(ret, day_info, true)

	ret.main_widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(10),
		weather_applet.main_widget,
		calendar.main_widget
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
