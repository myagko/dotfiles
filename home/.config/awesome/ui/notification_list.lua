local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local Notifications = require("daemons.notifications")

local notification_list = {}

notification_list.dnd_button = helpers.ui.create_hover_button {
    text = text_icons.bell_on,
    bg = beautiful.background,
    margins = { right = dpi(16), left = dpi(16) },
    buttons = {
        awful.button({}, 1, function()
            Notifications:toggle_silent()
            if Notifications.silent then
                notification_list.dnd_button:change_text(text_icons.bell_off)
            else
                notification_list.dnd_button:change_text(text_icons.bell_on)
            end
        end)
    }
}

notification_list.clear_button = helpers.ui.create_hover_button {
    text = text_icons.trash,
    fg = beautiful.red,
    bg = beautiful.background,
    bg_hover = beautiful.red,
    margins = { right = dpi(16), left = dpi(16) },
    buttons = {
        awful.button({}, 1, function()
            notification_list:reset_notifs()
        end)
    }
}

notification_list.count_msg = wibox.widget {
    widget = wibox.widget.textbox
}

notification_list.empty_massage = wibox.widget {
    widget = wibox.container.background,
    fg = beautiful.foreground_alt,
    forced_height = dpi(560),
    {
        widget = wibox.widget.textbox,
        align = "center",
        font = helpers.ui.font(beautiful.font_size + dpi(5)),
        text = "No notifications"
    }
}

notification_list.m_layout = wibox.widget {
    layout = wibox.layout.overflow.vertical,
    scrollbar_enabled = false,
    step = 80,
    spacing = dpi(10)
}


notification_list.main_widget = wibox.widget {
    widget = wibox.container.background,
    forced_height = dpi(50) + dpi(560),
    forced_width = dpi(450),
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            widget = wibox.container.background,
            forced_height = dpi(50),
            {
                layout = wibox.layout.align.horizontal,
                {
                    widget = wibox.container.margin,
                    margins = 16,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        spacing = dpi(10),
                        {
                            widget = wibox.widget.textbox,
                            align = "center",
                            text = "Notifications"
                        },
                        notification_list.count_msg
                    }
                },
                nil,
                {
                    layout = wibox.layout.fixed.horizontal,
                    spacing = beautiful.sep_width,
                    spacing_widget = helpers.ui.create_sep {
                        orientation = "v",
                        margins = { top = 6, bottom = 6 }
                    },
                    notification_list.dnd_button,
                    notification_list.clear_button
                }
            }
        },
        notification_list.m_layout
    }
}

function notification_list:update_count()
    if not self.is_empty then
        self.count_msg.text = "(" .. #self.m_layout.children .. ")"
    else
        self.count_msg.text = ""
    end
end

function notification_list:reset_notifs()
    self.m_layout:reset()
    self.m_layout:insert(1, self.empty_massage)
    self.is_empty = true
    self:update_count()
end

function notification_list:remove_notif(w)
    self.m_layout:remove_widgets(w)

    if #self.m_layout.children == 0 then
        self.m_layout:insert(1, self.empty_massage)
        self.is_empty = true
    end

    self:update_count()
    collectgarbage("collect")
end

function notification_list:create_notif(n)
    if not n.icon then
        n.icon = beautiful.notification_icon_bell
    end

    local nmassage = wibox.widget {
        widget = wibox.widget.textbox,
        text = n.massage or n.text
    }

    local ntitle = wibox.widget {
        widget = wibox.widget.textbox,
        text = n.title
    }

    local ntime = wibox.widget {
        widget = wibox.widget.textbox,
        font = helpers.ui.font(dpi(11)),
        markup = helpers.ui.colorize_markup(os.date("%H:%M"), beautiful.foreground_alt)
    }

    local nicon = wibox.widget {
        widget = wibox.widget.imagebox,
        resize = true,
        halign = "center",
        valign = "top",
        image = n.icon
    }

    local nclose = wibox.widget {
        widget = wibox.widget.textbox,
        text = text_icons.close
    }

    local nexpand = wibox.widget {
        widget = wibox.widget.textbox,
        text = text_icons.arrow_down
    }

    local nwidget = wibox.widget {
        widget = wibox.container.background,
        border_width = beautiful.border_width,
        border_color = beautiful.border_color,
        bg = beautiful.background_alt,
        forced_height = dpi(130),
        {
            widget = wibox.container.margin,
            margins = dpi(20),
            {
                layout = wibox.layout.fixed.horizontal,
                fill_space = true,
                spacing = dpi(20),
                {
                    widget = wibox.container.constraint,
                    height = dpi(85),
                    width = dpi(85),
                    strategy = "max",
                    nicon
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    spacing = dpi(5),
                    {
                        layout = wibox.layout.align.horizontal,
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(10),
                            {
                                widget = wibox.container.constraint,
                                width = dpi(150),
                                {
                                    widget = wibox.container.scroll.horizontal,
                                    step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
                                    speed = 50,
                                    ntitle
                                }
                            },
                            ntime
                        },
                        nil,
                        {
                            layout = wibox.layout.fixed.horizontal,
                            spacing = dpi(5),
                            nexpand,
                            nclose
                        }
                    },
                    helpers.ui.create_sep { orientation = "h", size = beautiful.sep_width },
                    nmassage
                }
            }
        }
    }

    if n.urgency == "critical" then
        nwidget.fg = beautiful.red
    end

    local is_expanded = false

    nexpand:buttons {
        awful.button({}, 1, function()
            is_expanded = not is_expanded
            if is_expanded then
                nwidget.forced_height = dpi(210)
                nexpand.text = text_icons.arrow_up
            else
                nwidget.forced_height = dpi(130)
                nexpand.text = text_icons.arrow_down
            end
        end)
    }

    nclose:buttons {
        awful.button({}, 1, function()
            self:remove_notif(nwidget)
        end)
    }

    return nwidget
end

function notification_list:add_notifs(n)
    if #self.m_layout.children == 1 and self.is_empty then
        self.m_layout:reset()
        self.is_empty = false
    end

    local appicon = n.icon or n.app_icon
    if not appicon then
        appicon = beautiful.icon_bell
    end

    if beautiful.notif_list_limit and #self.m_layout.children >= beautiful.notif_list_limit then
        self:remove_notif(self.m_layout.children[beautiful.notif_list_limit])
    end

    self.m_layout:insert(1, self:create_notif(n))
    self:update_count()
end

notification_list.is_empty = true
notification_list.m_layout:insert(1, notification_list.empty_massage)

naughty.connect_signal("request::display", function(n)
    notification_list:add_notifs(n)
end)

return notification_list
