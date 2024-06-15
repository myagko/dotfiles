local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local Wifi_daemon = require("daemons.wifi")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local wifi_applet = {
    rows = 8
}

wifi_applet.control_button_label = wibox.widget {
    widget = wibox.widget.textbox
}

wifi_applet.control_button_revealer = wibox.widget {
    widget = wibox.widget.textbox,
    text = text_icons.arrow_right
}

wifi_applet.control_button = wibox.widget {
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
            wifi_applet.control_button_label,
            nil,
            wifi_applet.control_button_revealer
        }
    }
}

wifi_applet.close_button = helpers.ui.create_hover_button {
    text = text_icons.arrow_left,
    forced_width = dpi(55),
    forced_height = dpi(55),
}

wifi_applet.refresh_button = helpers.ui.create_hover_button {
    text = text_icons.reboot,
    forced_width = dpi(55),
    forced_height = dpi(55),
    buttons = {
        awful.button({}, 1, function()
            wifi_applet:refresh()
        end)
    }
}

wifi_applet.toggle_button = helpers.ui.create_hover_button {
    forced_width = dpi(55),
    forced_height = dpi(55),
    font = helpers.ui.font(beautiful.font_size + dpi(5)),
    buttons = {
        awful.button({}, 1, function()
            Wifi_daemon:toggle()
        end)
    }
}

wifi_applet.massage_textbox = wibox.widget {
    widget = wibox.widget.textbox,
    align = "center",
    font = helpers.ui.font(beautiful.font_size + dpi(5))
}

wifi_applet.massage = wibox.widget {
    widget = wibox.container.background,
    fg = beautiful.foreground_alt,
    forced_height = dpi(55)*wifi_applet.rows,
    wifi_applet.massage_textbox
}

wifi_applet.passbox_title = wibox.widget {
    widget = wibox.widget.textbox
}

wifi_applet.passbox_prompt = wibox.widget {
    widget = wibox.widget.textbox
}

wifi_applet.passbox = wibox.widget {
    widget = wibox.container.background,
    forced_height = dpi(55)*wifi_applet.rows,
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(20),
        {
            widget = wibox.container.margin,
            margins = dpi(10),
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = dpi(20),
                {
                    widget = wibox.container.background,
                    buttons = {
                        awful.button({}, 1, function()
                            wifi_applet:close_passbox()
                        end)
                    },
                    {
                        widget = wibox.widget.textbox,
                        text = text_icons.arrow_left
                    }
                },
                wifi_applet.passbox_title
            }
        },
        {
            widget = wibox.container.background,
            bg = beautiful.background_alt,
            fg = beautiful.foreground_alt,
            border_width = beautiful.comp_border_width,
            border_color = beautiful.border_color,
            {
                widget = wibox.container.margin,
                margins = dpi(10),
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(10),
                    {
                        widget = wibox.widget.textbox,
                        text = "Password: "
                    },
                    {
                        widget = wibox.container.background,
                        fg = beautiful.foreground,
                        wifi_applet.passbox_prompt
                    }
                }
            }
        }
    }
}

wifi_applet.main_widget_layout = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(15)
}

wifi_applet.main_widget = wibox.widget {
    widget = wibox.container.background,
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(20),
        {
            widget = wibox.container.background,
            forced_height = dpi(55)*wifi_applet.rows,
            forced_width = dpi(400),
            wifi_applet.main_widget_layout
        },
        {
            widget = wibox.container.background,
            bg = beautiful.background_alt,
            border_width = beautiful.comp_border_width,
            border_color = beautiful.border_color,
            forced_height = dpi(55),
            {
                layout = wibox.layout.align.horizontal,
                wifi_applet.toggle_button,
                nil,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = beautiful.sep_width,
                    spacing_widget = helpers.ui.create_sep {
                        orientation = "v",
                        margins = { top = 6, bottom = 6 }
                    },
                    wifi_applet.refresh_button,
                    wifi_applet.close_button
                }
            }
        }
    }
}

wifi_applet.control_button_label:buttons {
    awful.button({}, 1, function()
        Wifi_daemon:toggle()
    end)
}

function wifi_applet:add_entries(list)
    self.main_widget_layout:reset()

    local ap_container = wibox.widget {
        layout = wibox.layout.overflow.vertical,
        scrollbar_enabled = false,
        step = 80
    }

    for _, entry in ipairs(list) do
        local entry_info = wibox.widget {
            widget = wibox.widget.textbox
        }
        local wifi_entry = wibox.widget {
            widget = wibox.container.background,
            forced_height = dpi(55),
            {
                widget = wibox.container.margin,
                margins = dpi(10),
                {
                    layout = wibox.layout.align.horizontal,
                    {
                        widget = wibox.widget.textbox,
                        text = entry.ssid
                    },
                    nil,
                    entry_info
                }
            }
        }

        if entry.active == "yes" then
            entry_info.text = text_icons.selected
            ap_container:add(wifi_entry)
        elseif entry.active == "no" then
            if entry.security:match("WPA") then
                entry_info.text = text_icons.lock
            else
                entry_info.text = text_icons.unlock
            end
            wifi_entry.buttons = {
                awful.button({}, 1, function()
                    self:enter_passwd(entry.ssid, entry.bssid, entry.security)
                end)
            }
            ap_container:add(wifi_entry)
        end
    end

    self.main_widget_layout:add(ap_container)
    collectgarbage("collect")
end

function wifi_applet:enter_passwd(ssid, bssid, security)
    self.passbox.state = true
    self.main_widget_layout:reset()
    self.main_widget_layout:add(self.passbox)
    self.passbox_title.text = ssid

    awful.prompt.run {
        textbox = self.passbox_prompt,
        bg_cursor = beautiful.foreground,
        done_callback = function()
            self.main_widget_layout:reset()
            Wifi_daemon:get_status()
        end,
        exe_callback = function(input)
            Wifi_daemon:connect(ssid, bssid, security, input)
            self:refresh()
        end
    }
end

function wifi_applet:close_passbox()
    self.passbox.state = false
    awful.keygrabber.stop()
    self.main_widget_layout:reset()
    Wifi_daemon:get_status()
end

function wifi_applet:refresh()
    Wifi_daemon:get_status()
end

awesome.connect_signal("wifi:status", function(status)
    if status then
        wifi_applet.toggle_button:change_text(text_icons.switch_on)
        wifi_applet.control_button_label.text = text_icons.wifi_on .. " Enabled"
        wifi_applet.control_button.bg = beautiful.accent
        wifi_applet.control_button.fg = beautiful.background
    else
        wifi_applet.toggle_button:change_text(text_icons.switch_off)
        wifi_applet.massage_textbox.text = "Wifi disabled"
        wifi_applet.control_button_label.text = text_icons.wifi_on .. " Disabled"
        wifi_applet.control_button.bg = beautiful.background_alt
        wifi_applet.control_button.fg = beautiful.foreground
        wifi_applet.main_widget_layout:reset()
        wifi_applet.main_widget_layout:add(wifi_applet.massage)
    end
end)

awesome.connect_signal("wifi:scan_started", function()
    wifi_applet.main_widget_layout:reset()
    wifi_applet.main_widget_layout:add(wifi_applet.massage)
    wifi_applet.massage_textbox.text = "Please wait"
end)

awesome.connect_signal("wifi:scan_finished", function(wifi_list)
    wifi_applet:add_entries(wifi_list)
end)

return wifi_applet
