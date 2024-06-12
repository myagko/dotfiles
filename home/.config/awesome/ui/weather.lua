local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local weather = {}

function weather:create_current(w)
    local curr_temp = wibox.widget {
        widget = wibox.widget.textbox,
        align = "left",
        font = helpers.ui.font(dpi(25)),
        text = w.current.weather_icon .. " " .. string.gsub(tostring(math.floor(w.current.temp)), "%-0", "0") .. "°C "
    }

    local curr_desc = wibox.widget {
        widget = wibox.widget.textbox,
        align = "left",
        wrap = "word",
        text = w.current.weather_desc
    }

    local curr_feels_like = wibox.widget {
        widget = wibox.widget.textbox,
        align = "left",
        text = "Feels like: " .. string.gsub(tostring(math.floor(w.current.feels_like)), "%-0", "0") .. "°C"
    }

    local curr_humidity = wibox.widget {
        widget = wibox.widget.textbox,
        align = "right",
        text = "Humidity: " .. tostring(math.floor(w.current.humidity)) .. "%"
    }

    local curr_wind = wibox.widget {
        widget = wibox.widget.textbox,
        align = "right",
        text = "Wind: " .. w.current.wind_speed .. " m/s (" .. tostring(helpers.util.to_direction(w.current.wind_deg)) .. ")"
    }

    local curr_uvi = wibox.widget {
        widget = wibox.widget.textbox,
        align = "right",
        text = "UV index: " .. tostring(math.floor(w.current.uvi))
    }

    local curr_pressure = wibox.widget {
        widget = wibox.widget.textbox,
        align = "right",
        text = "pressure: " .. tostring(math.floor(helpers.util.hPa_to_mmHg(w.current.pressure))) .. " mmHg"
    }

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        {
            layout = wibox.layout.align.horizontal,
            {
                widget = wibox.container.background,
                forced_width = dpi(180),
                forced_height = dpi(130),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(5),
                    curr_temp,
                    curr_feels_like,
                    curr_desc
                }
            },
            nil,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                curr_pressure,
                curr_wind,
                curr_humidity,
                curr_uvi
            }
        }
    }
end

function weather:create_daily(w)
    local day_layout = wibox.widget {
        layout = wibox.layout.overflow.horizontal,
        scrollbar_enabled = false,
        step = 40,
        spacing = dpi(5)
    }

    for _, v in ipairs(w.daily) do
        local temp = wibox.widget {
            widget = wibox.widget.textbox,
            align = "center",
            halign = "bottom",
            text = string.gsub(tostring(math.floor(v.temp_day)), "%-0", "0") .. "°/" .. string.gsub(tostring(math.floor(v.temp_night)), "%-0", "0") .. "°"
        }

        local icon = wibox.widget {
            widget = wibox.widget.textbox,
            align = "center",
            font = helpers.ui.font(dpi(25)),
            text = v.weather_icon
        }

        local day = wibox.widget {
            widget = wibox.widget.textbox,
            align = "center",
            text = os.date("%a", v.dt)
        }

        day_layout:add(wibox.widget {
            widget = wibox.container.background,
            forced_width = dpi(100),
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(5),
                day,
                icon,
                temp
            }
        })
    end

    return wibox.widget {
        widget = wibox.container.margin,
        margins = dpi(15),
        day_layout
    }
end

weather.err_msg = wibox.widget {
    widget = wibox.container.background,
    bg = beautiful.background_alt,
    forced_height = dpi(200),
    {
        widget = wibox.widget.textbox,
        align = "center",
        text = "No weather data."
    }
}

weather.main_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical
}

weather.main_widget = wibox.widget {
    widget = wibox.container.background,
    forced_width = dpi(450),
    bg = beautiful.background_alt,
    border_width = beautiful.comp_border_width,
    border_color = beautiful.border_color,
    weather.main_layout
}

awesome.connect_signal("weather", function(w)
    weather.main_layout:reset()
    if w then
        weather.main_layout:add(
            weather:create_current(w),
            helpers.ui.create_sep {
                orientation = "h",
                size = beautiful.sep_width,
                margins = { left = dpi(10), right = dpi(10) }
            },
            weather:create_daily(w)
        )
    else
        weather.main_layout:add(weather.err_msg)
    end
end)

return weather
