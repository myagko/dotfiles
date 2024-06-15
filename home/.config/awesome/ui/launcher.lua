local awful = require("awful")
local wibox = require("wibox")
local Gio = require("lgi").Gio
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local Powermenu = require("ui.powermenu")
local Control = require("ui.control")
local Day_info = require("ui.day_info")

local launcher = {
    sidebar = {},
    rows = 6
}

launcher.sidebar.control_button = helpers.ui.create_hover_button {
    text = text_icons.gear,
    forced_width = dpi(55),
    forced_height = dpi(55),
    buttons = {
        awful.button({}, 1, function()
            Control:open()
        end)
    }
}

launcher.sidebar.day_info_button = helpers.ui.create_hover_button {
    text = text_icons.calendar,
    forced_width = dpi(55),
    forced_height = dpi(55),
    buttons = {
        awful.button({}, 1, function()
            Day_info:open()
        end)
    }
}

launcher.sidebar.poweroff_button = helpers.ui.create_hover_button {
    text = text_icons.poweroff,
    forced_width = dpi(55),
    forced_height = dpi(55),
    fg = beautiful.red,
    bg_hover = beautiful.red,
    buttons = {
        awful.button({}, 1, function()
            Powermenu:open()
        end)
    }
}

launcher.sidebar.main_widget = wibox.widget {
    widget = wibox.container.background,
    bg = beautiful.background_alt,
    border_width = beautiful.comp_border_width,
    border_color = beautiful.border_color,
    forced_width = dpi(55),
    {
        layout = wibox.layout.align.vertical,
        launcher.sidebar.poweroff_button,
        nil,
        {
            layout = wibox.layout.fixed.vertical,
            spacing = beautiful.sep_width,
            spacing_widget = helpers.ui.create_sep {
                orientation = "h",
                margins = { left = 6, right = 6 }
            },
            launcher.sidebar.day_info_button,
            launcher.sidebar.control_button
        }
    }
}

launcher.main_widget = wibox.widget {
    widget = wibox.container.margin,
    forced_width = dpi(290) + dpi(55) + dpi(10)*3,
    margins = dpi(10),
    {
        widget = wibox.container.background,
        forced_height = dpi(55)*(launcher.rows + 1) + dpi(10),
        {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10),
            fill_space = true,
            {
                layout = wibox.layout.fixed.vertical,
                spacing = dpi(10),
                {
                    widget = wibox.container.background,
                    bg = beautiful.border_color,
                    forced_height = dpi(55),
                    forced_width = dpi(55),
                    {
                        widget = wibox.container.margin,
                        margins = { bottom = beautiful.sep_width },
                        {
                            widget = wibox.container.background,
                            bg = beautiful.background,
                            {
                                widget = wibox.container.margin,
                                margins = { left = dpi(10), right = dpi(10) },
                                {
                                    id = "prompt",
                                    widget = wibox.widget.textbox
                                }
                            }
                        }
                    }
                },
                {
                    id = "entries_container",
                    layout = wibox.layout.fixed.vertical,
                    forced_width = dpi(290)
                }
            },
            launcher.sidebar.main_widget
        }
    }
}

launcher.popup_widget = awful.popup {
    ontop = true,
    visible = false,
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
                launcher.main_widget
            }
        }
    }
}

function launcher:next()
    if self.index_entry ~= #self.filtered and #self.filtered > 1 then
        self.index_entry = self.index_entry + 1
        if self.index_entry > self.index_start + self.rows - 1 then
            self.index_start = self.index_start + 1
        end
    else
        self.index_entry = 1
        self.index_start = 1
    end
end

function launcher:back()
    if self.index_entry ~= 1 and #self.filtered > 1 then
        self.index_entry = self.index_entry - 1
        if self.index_entry < self.index_start then
            self.index_start = self.index_start - 1
        end
    else
        self.index_entry = #self.filtered
        if #self.filtered < self.rows then
            self.index_start = 1
        else
            self.index_start = #self.filtered - self.rows + 1
        end
    end
end

function launcher.get_apps()
    local apps = {}
    for _, app in ipairs(Gio.AppInfo.get_all()) do
        if app:should_show() then
            table.insert(apps, {
                appinfo = app,
                name = app:get_name(),
                executable = app:get_executable()
            })
        end
    end

    return apps
end

function launcher:filter()
    local clear_input = self.input:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%[", "%%["):gsub("%]", "%%]")

    self.filtered = {}
    self.filtered_any = {}

    for _, entry in ipairs(self.unfiltered) do
        if entry.name:lower():sub(1, clear_input:len()) == clear_input:lower() or entry.executable:lower():sub(1, clear_input:len()) == clear_input:lower() then
            table.insert(self.filtered, entry)
        elseif entry.name:lower():match(clear_input:lower()) or entry.executable:lower():sub(1, clear_input:len()) == clear_input:lower() then
            table.insert(self.filtered_any, entry)
        end
    end

    table.sort(self.filtered, function(a, b) return a.name:lower() < b.name:lower() end)
    table.sort(self.filtered_any, function(a, b) return a.name:lower() < b.name:lower() end)

    for i = 1, #self.filtered_any do
        self.filtered[#self.filtered + 1] = self.filtered_any[i]
    end
end

function launcher:add_entries()
    local entries_container = self.main_widget:get_children_by_id("entries_container")[1]
    entries_container:reset()

    if self.index_entry > #self.filtered and #self.filtered ~= 0 then
        self.index_start, self.index_entry = 1, 1
    elseif self.index_entry < 1 then
        self.index_entry, self.index_start = 1, 1
    end

    for i, entry in ipairs(self.filtered) do
        local entry_widget = wibox.widget {
            forced_height = dpi(55),
            buttons = {
                awful.button({}, 1, function()
                    if self.index_entry == i then
                        entry.appinfo:launch()
                        self:close()
                    else
                        self.index_entry = i
                        self:filter()
                        self:add_entries()
                    end
                end),
                awful.button({}, 4, function()
                    self:back()
                    self:filter()
                    self:add_entries()
                end),
                awful.button({}, 5, function()
                    self:next()
                    self:filter()
                    self:add_entries()
                end),
            },
            widget = wibox.container.background,
            {
                widget = wibox.container.margin,
                margins = dpi(10),
                {
                    widget = wibox.widget.textbox,
                    text = entry.name
                }
            }
        }

        if self.index_start <= i and i <= self.index_start + self.rows - 1 then
            entries_container:add(entry_widget)
        end

        if i == self.index_entry then
            entry_widget.bg = beautiful.accent
            entry_widget.fg = beautiful.background
        end
    end

    collectgarbage("collect")
end

function launcher:run_prompt()
    local prompt = self.main_widget:get_children_by_id("prompt")[1]

    awful.prompt.run {
        prompt = "Launch: ",
        textbox = prompt,
        bg_cursor = beautiful.foreground,
        done_callback = function()
            self:close()
        end,
        changed_callback = function(input)
            self.input = input
            self:filter()
            self:add_entries()
        end,
        exe_callback = function(input)
            if self.filtered[self.index_entry] then
                self.filtered[self.index_entry].appinfo:launch()
            else
                awful.spawn.with_shell(input)
            end
        end,
        keypressed_callback = function(_, key)
            if key == "Down" then
                self:next()
            elseif key == "Up" then
                self:back()
            end
        end
    }
end

function launcher:open()
    if self.state then return end
    self.state = true
    self.popup_widget.visible = true
    self:send_state()

    self.index_start, self.index_entry = 1, 1
    self.unfiltered = self.get_apps()

    self.input = ""
    self:filter()
    self:add_entries()

    awful.keygrabber.stop()
    self:run_prompt()

    self.popup_widget.placement = function(d)
        awful.placement.bottom_right(d, { honor_workarea = true, margins = beautiful.useless_gap * 2 })
    end
end

function launcher:close()
    if not self.state then return end
    self.state = false
    awful.keygrabber.stop()
    self.popup_widget.visible = false
    self:send_state()
end

function launcher:toggle()
    if not self.popup_widget.visible then
        self:open()
    else
        self:close()
    end
end

function launcher:send_state()
    awesome.emit_signal("launcher:state", self.state)
end

awesome.connect_signal("powermenu:state", function(state)
    if state then launcher:close() end
end)

awesome.connect_signal("control:state", function(state)
    if state then launcher:close() end
end)

awesome.connect_signal("day_info:state", function(state)
    if state then launcher:close() end
end)

return launcher
