local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local common = require("common")
local dpi = beautiful.xresources.apply_dpi
local capi = { screen = screen }
local weather_applet = require("ui.day_info_panel.weather_applet")

local day_info = {}

function day_info:open()
	if self.state then return end
	self.state = true
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

	ret.weather_applet = weather_applet()

	ret.calendar = common.calendar {
		sun_start = false,
		shape = beautiful.rrect(dpi(10)),
		day_shape = beautiful.rrect(dpi(8))
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(12),
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(6),
			ret.weather_applet.main_widget,
			ret.calendar
		}
	}

	ret.popup_widget = awful.popup {
		visible = false,
		ontop = true,
		screen = capi.screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color_normal,
		--shape = beautiful.rrect(dpi(20)),
		placement = function(d)
			awful.placement.bottom_right(d, {
				honor_workarea = true,
				margins = beautiful.useless_gap
			})
		end,
		widget = ret.main_widget
	}

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return {
	get_default = get_default
}
