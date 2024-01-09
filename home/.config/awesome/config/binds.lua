local awful = require("awful")
local User = require("user")
local modkey = "Mod4"

local Menu = require("ui.menu")
local Launcher = require("ui.launcher")
local Powermenu = require("ui.powermenu")
local Control_center = require("ui.control_center")
local Screenshot = require("daemons.screenshot")

awful.mouse.append_global_mousebindings({
	awful.button({}, 3, function()
		Menu:toggle()
	end),
	awful.button({}, 4, awful.tag.viewprev),
	awful.button({}, 5, awful.tag.viewnext),
})
awful.mouse.snap.edge_enabled = false

awful.keyboard.append_global_keybindings({
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.byidx(1)
		if client.focus then
			client.focus:raise()
		end
	end)
})

awful.keyboard.append_global_keybindings({
	awful.key {
		modifiers = { modkey },
		keygroup = "numrow",
		on_press = function(index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				tag:view_only()
			end
		end,
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
		end,
	}
})

awful.keyboard.append_global_keybindings({
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
})

client.connect_signal("request::default_mousebindings", function()
	awful.mouse.append_client_mousebindings({
		awful.button({}, 1, function(c)
			c:activate { context = "mouse_click" }
		end),
		awful.button({ modkey }, 1, function(c)
			c:activate { context = "mouse_click", action = "mouse_move" }
		end),
		awful.button({ modkey }, 3, function(c)
			c:activate { context = "mouse_click", action = "mouse_resize" }
		end),
	})
end)

client.connect_signal("request::default_keybindings", function()
	awful.keyboard.append_client_keybindings({
		awful.key({ modkey }, "v", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end),
		awful.key({ modkey }, "z", function(c)
			c:kill()
		end),
		awful.key({ modkey }, "x", function(c)
			c.minimized = true
		end),
		awful.key({ modkey }, "c", function(c)
			c.maximized = not c.maximized
			c:raise()
		end),
		awful.key({ modkey }, "b", function(c)
			awful.placement.centered(c, { honor_workarea = true })
		end),
	})
end)

awful.keyboard.append_global_keybindings({
	awful.key({ modkey, "Shift" }, "r", function()
		awesome.restart()
	end),
	awful.key({ modkey }, "w", function()
		awful.spawn(User.terminal)
	end),
	awful.key({ modkey }, "d", function()
		Launcher:open()
	end),
	awful.key({ modkey }, "q", function()
		Powermenu:open()
	end),
	awful.key({ modkey }, "f", function()
		Control_center:toggle()
	end),
	awful.key({}, "Print", function()
		Screenshot:full()
	end),
	awful.key({ "Shift" }, "Print", function()
		Screenshot:select()
	end),
})

client.connect_signal("button::press", function()
	Launcher:close()
	Control_center:close()
	Menu:hide()
	Powermenu:close()
end)

awful.mouse.append_global_mousebinding(
	awful.button({}, 1, function()
		Launcher:close()
		Control_center:close()
		Menu:hide()
		Powermenu:close()
	end)
)
