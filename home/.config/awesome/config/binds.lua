local awful = require("awful")
local User = require("user")
local modkey = "Mod4"

local Screenshot = require("daemons.screenshot")
local Menu = require("ui.menu")
local Launcher = require("ui.launcher")
local Powermenu = require("ui.powermenu")
local Control = require("ui.control")
local Day_info = require("ui.day_info")

awful.mouse.append_global_mousebindings {
    awful.button({}, 3, function() Menu:toggle() end),
    awful.button({}, 4, awful.tag.viewprev),
    awful.button({}, 5, awful.tag.viewnext),
}

awful.mouse.snap.edge_enabled = false

awful.keyboard.append_global_keybindings {
    awful.key({ modkey }, "Tab", function()
        awful.client.focus.byidx(1)
        if client.focus then
            client.focus:raise()
        end
    end)
}

awful.keyboard.append_global_keybindings {
    awful.key {
        modifiers = { modkey },
        keygroup = "numrow",
        on_press = function(index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                tag:view_only()
            end
        end
    },
    awful.key {
        modifiers = { modkey, "Shift" },
        keygroup = "numrow",
        on_press = function(index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end
    }
}

--[[
-- tiling keys
awful.keyboard.append_global_keybindings {
    awful.key({ modkey, "Shift" }, "l", function()
        awful.client.swap.byidx(1)
    end),
    awful.key({ modkey, "Shift" }, "s", function()
        awful.client.swap.byidx(1)
    end),
    awful.key({ modkey, "Control" }, "s", function()
        awful.client.swap.byidx(-1)
    end),
    awful.key({ modkey, "Shift" }, "a", function()
        awful.tag.incnmaster(1, nil, true)
    end),
    awful.key({ modkey, "Control" }, "a", function()
        awful.tag.incnmaster(-1, nil, true)
    end),
    awful.key({ modkey, "Shift" }, "q", function()
        awful.tag.incncol(1, nil, true)
    end),
    awful.key({ modkey, "Control" }, "q", function()
        awful.tag.incncol(-1, nil, true)
    end),
    awful.key({ modkey, "Shift" }, "e", function()
        awful.tag.incmwfact(0.05)
    end),
    awful.key({ modkey, "Control" }, "e", function()
        awful.tag.incmwfact(-0.05)
    end),
    awful.key({ modkey, "Control", "Shift" }, "e", function()
        awful.tag.setmwfact(0.5)
    end),
    awful.key({ modkey, }, "space", function()
        awful.layout.inc(1)
    end),
}
]]

client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings {
        awful.button({}, 1, function(c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ modkey }, 1, function(c)
            c:activate { context = "mouse_click", action = "mouse_move" }
        end),
        awful.button({ modkey }, 3, function(c)
            c:activate { context = "mouse_click", action = "mouse_resize" }
        end)
    }
end)

client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings {
        awful.key({ modkey }, "z", function(c)
            c:kill()
        end),
        awful.key({ modkey }, "x", function(c)
            c.minimized = true
        end),
        awful.key({ modkey }, "c", function(c)
            c.fullscreen = false
            c.maximized = not c.maximized
            c:raise()
        end),
        awful.key({ modkey }, "v", function(c)
            c.maximized = false
            c.fullscreen = not c.fullscreen
            c:raise()
        end),
        awful.key({ modkey }, "b", function(c)
            awful.placement.centered(c, { honor_workarea = true })
        end),
        awful.key({ modkey }, "n", function(c)
            c.ontop = not c.ontop
            c:raise()
        end),
    }
end)

awful.keyboard.append_global_keybindings {
    awful.key({ modkey, "Shift" }, "r", function() awesome.restart() end),
    awful.key({ modkey }, "w", function() awful.spawn(User.terminal) end),
    awful.key({ modkey }, "d", function() Launcher:open() end),
    awful.key({ modkey }, "q", function() Powermenu:open() end),
    awful.key({}, "Print", function() Screenshot:full() end),
    awful.key({ "Shift" }, "Print", function() Screenshot:select() end)
}

client.connect_signal("button::press", function()
    Menu:hide()
    Launcher:close()
    Powermenu:close()
    Control:close()
    Day_info:close()
end)

awful.mouse.append_global_mousebinding(
    awful.button({}, 1, function()
        Menu:hide()
        Launcher:close()
        Powermenu:close()
        Control:close()
        Day_info:close()
    end)
)
