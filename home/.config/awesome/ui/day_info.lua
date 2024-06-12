local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local Weather = require("ui.weather")
local Calendar = require("ui.calendar")

local day_info = {}

day_info.main_widget = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(10),
    Weather.main_widget,
    Calendar.main_widget
}

day_info.popup_widget = awful.popup {
    visible = false,
    ontop = true,
    screen = screen.primary,
    widget = {
        widget = wibox.container.background,
        bg = beautiful.background_urgent,
        {
            widget = wibox.container.margin,
            margins = beautiful.border_width,
            {
                widget = wibox.container.background,
                bg = beautiful.background,
                {
                    widget = wibox.container.margin,
                    margins = dpi(20),
                    day_info.main_widget
                }
            }
        }
    }
}

function day_info:open()
    if self.state then return end
    self.state = true
    self.popup_widget.visible = true
    self:send_state()
    self.popup_widget.placement = function(d)
        awful.placement.bottom_right(d, { honor_workarea = true, margins = beautiful.useless_gap * 2 })
    end
    Calendar:set(os.date("*t"))
end

function day_info:close()
    if not self.state then return end
    self.state = false
    self.popup_widget.visible = false
    self:send_state()
end

function day_info:toggle()
    if not self.popup_widget.visible then
        self:open()
    else
        self:close()
    end
end

function day_info:send_state()
    awesome.emit_signal("day_info:state", self.state)
end

awesome.connect_signal("launcher:state", function(state)
    if state then day_info:close() end
end)

awesome.connect_signal("powermenu:state", function(state)
    if state then day_info:close() end
end)

awesome.connect_signal("control:state", function(state)
    if state then day_info:close() end
end)

return day_info
