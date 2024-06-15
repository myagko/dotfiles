local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local Bluetooth_daemon = require("daemons.bluetooth")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local bluetooth_applet = {
    rows = 8
}

bluetooth_applet.control_button_label = wibox.widget {
    widget = wibox.widget.textbox
}

bluetooth_applet.control_button_revealer = wibox.widget {
    widget = wibox.widget.textbox,
    text = text_icons.arrow_right
}

bluetooth_applet.control_button = wibox.widget {
    widget = wibox.container.background,
    bg = beautiful.background_alt,
    fg = beautiful.foreground,
    border_width = beautiful.comp_border_width,
    border_color = beautiful.border_color,
    forced_height = dpi(55),
    {
        widget = wibox.container.margin,
        margins = { left = dpi(15), right = dpi(15) },
        {
            layout = wibox.layout.align.horizontal,
            bluetooth_applet.control_button_label,
            nil,
            bluetooth_applet.control_button_revealer
        }
    }
}

bluetooth_applet.close_button = helpers.ui.create_hover_button {
    text = text_icons.arrow_left,
    forced_width = dpi(55),
    forced_height = dpi(55)
}

bluetooth_applet.refresh_button = helpers.ui.create_hover_button {
    text = text_icons.reboot,
    forced_width = dpi(55),
    forced_height = dpi(55)
}

bluetooth_applet.toggle_button = helpers.ui.create_hover_button {
    forced_width = dpi(55),
    forced_height = dpi(55),
    font = helpers.ui.font(beautiful.font_size + dpi(5)),
    buttons = {
        awful.button({}, 1, function()
            Bluetooth_daemon:toggle()
        end)
    }
}

bluetooth_applet.massage_textbox = wibox.widget {
    widget = wibox.widget.textbox,
    align = "center",
    font = helpers.ui.font(beautiful.font_size + dpi(5))
}

bluetooth_applet.massage = wibox.widget {
    widget = wibox.container.background,
    fg = beautiful.foreground_alt,
    forced_height = dpi(55)*bluetooth_applet.rows,
    bluetooth_applet.massage_textbox
}

bluetooth_applet.main_widget_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(15)
}

bluetooth_applet.main_widget = wibox.widget {
    widget = wibox.container.background,
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(20),
        {
            widget = wibox.container.background,
            forced_height = dpi(55)*bluetooth_applet.rows,
            forced_width = dpi(400),
            bluetooth_applet.main_widget_layout
        },
        {
            widget = wibox.container.background,
            bg = beautiful.background_alt,
            border_width = beautiful.comp_border_width,
            border_color = beautiful.border_color,
            forced_height = dpi(55),
            {
                layout = wibox.layout.align.horizontal,
                bluetooth_applet.toggle_button,
                nil,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = beautiful.sep_width,
                    spacing_widget = helpers.ui.create_sep {
                        orientation = "v",
                        margins = { top = 6, bottom = 6 }
                    },
                    bluetooth_applet.refresh_button,
                    bluetooth_applet.close_button
                }
            }
        }
    }
}

bluetooth_applet.control_button_label:buttons {
    awful.button({}, 1, function()
        Bluetooth_daemon:toggle()
    end)
}

awesome.connect_signal("bluetooth:status", function(status)
    if status then
        bluetooth_applet.toggle_button:change_text(text_icons.switch_on)
        bluetooth_applet.control_button_label.text = text_icons.bluetooth_on .. " Enabled"
        bluetooth_applet.control_button.bg = beautiful.accent
        bluetooth_applet.control_button.fg = beautiful.background
        bluetooth_applet.massage_textbox.text = "wip"
        bluetooth_applet.main_widget_layout:add(bluetooth_applet.massage)
    else
        bluetooth_applet.toggle_button:change_text(text_icons.switch_off)
        bluetooth_applet.control_button_label.text = text_icons.bluetooth_on .. " Disabled"
        bluetooth_applet.control_button.bg = beautiful.background_alt
        bluetooth_applet.control_button.fg = beautiful.foreground
        bluetooth_applet.main_widget_layout:reset()
        bluetooth_applet.massage_textbox.text = "Bluetooth disabled"
        bluetooth_applet.main_widget_layout:add(bluetooth_applet.massage)
    end
end)

return bluetooth_applet
