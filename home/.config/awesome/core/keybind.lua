local awful = require("awful")
local modkey = "Mod4"
local user = require("user")
local capi = { awesome = awesome, client = client }
local screenshot = require("services.screenshot").get_default()
local menu = require("ui.menu")
local launcher = require("ui.launcher").get_default()
local powermenu = require("ui.powermenu").get_default()
local control_panel = require("ui.control_panel").get_default()

awful.mouse.snap.edge_enabled = false

awful.mouse.append_global_mousebindings {
	awful.button({}, 3, function() menu:toggle_desktop_menu() end),
	awful.button({}, 4, awful.tag.viewprev),
	awful.button({}, 5, awful.tag.viewnext)
}

awful.keyboard.append_global_keybindings {
	awful.key({ modkey }, "Tab", function()
		awful.client.focus.byidx(1)
		if client.focus then
			client.focus:raise()
		end
	end),
	awful.key({ modkey, "Shift" }, "Tab", function()
		awful.client.focus.byidx(-1)
		if client.focus then
			client.focus:raise()
		end
	end),
	awful.key({ modkey, "Control" }, "Tab", function ()
		local restored = awful.client.restore()
		if restored then
			client.focus = restored
			client.focus:raise()
		end
	end),
	awful.key {
		modifiers = { modkey },
		keygroup = "numrow",
		on_press = function (index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				tag:view_only()
			end
		end
	},
	awful.key {
		modifiers = { modkey, "Control" },
		keygroup = "numrow",
		on_press = function (index)
			local screen = awful.screen.focused()
			local tag = screen.tags[index]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end
	},
	awful.key {
		modifiers = { modkey, "Shift" },
		keygroup = "numrow",
		on_press = function (index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end
	},
	awful.key {
		modifiers = { modkey, "Control", "Shift" },
		keygroup = "numrow",
		on_press = function (index)
			if client.focus then
				local tag = client.focus.screen.tags[index]
				if tag then
					client.focus:toggle_tag(tag)
				end
			end
		end
	},
	awful.key {
		modifiers = { modkey },
		keygroup = "numpad",
		on_press = function (index)
			local t = awful.screen.focused().selected_tag
			if t then
				t.layout = t.layouts[index] or t.layout
			end
		end
	},
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
	awful.key({ modkey, "Shift" }, "r", function()
		capi.awesome.emit_signal("request::restart")
	end),
	awful.key({ modkey }, "Return", function()
		awful.spawn(user.terminal)
	end),
	awful.key({ modkey }, "d", function()
		launcher:open()
	end),
	awful.key({ modkey }, "f", function()
		control_panel:toggle()
	end),
	awful.key({ modkey }, "q", function()
		powermenu:open()
	end),
	awful.key({}, "Print", function()
		screenshot:take_full()
	end),
	awful.key({"Shift"}, "Print", function()
		screenshot:take_select()
	end)
}

capi.client.connect_signal("request::default_mousebindings", function()
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


capi.client.connect_signal("request::default_keybindings", function()
	awful.keyboard.append_client_keybindings {
		awful.key({ modkey }, "z", function(c)
			c:kill()
		end),
		awful.key({ modkey }, "x", function(c)
			c.maximized = not c.maximized
			c:raise()
		end),
		awful.key({ modkey }, "c", function(c)
			c.minimized = true
		end),
		awful.key({ modkey }, "v", function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end),
		awful.key({ modkey }, "b", function(c)
			c.ontop = not c.ontop
			c:raise()
		end),
		awful.key({ modkey }, "m", function(c)
			menu:toggle_client_menu(c)
		end),
		awful.key({ modkey, "Control" }, "Return", function(c)
			c:swap(awful.client.getmaster())
		end)
	}
end)
