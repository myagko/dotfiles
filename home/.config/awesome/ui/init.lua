local awful = require("awful")
local naughty = require("naughty")
local helpers = require("helpers")
local user = require("user")
local Titlebar = require("ui.titlebars")
local Wallpaper = require("ui.wallpaper")
local bar = require("ui.bar")
local notifications = require("ui.notifications")
local launcher = require("ui.launcher")
local powermenu = require("ui.powermenu")
local control = require("ui.control_panel")
local day_info = require("ui.day_info_panel")
local desktop_menu = require("ui.desktop_menu")
local client_menu = require("ui.client_menu")

local function set_wibar_hideaway(wibar)
	client.connect_signal("request::manage", function(c)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen ~= focused_screen then return end
		if helpers.has_common_values(c:tags(), focused_screen.selected_tags) and c.fullscreen then
			wibar.visible = false
		else
			wibar.visible = true
		end
	end)

	client.connect_signal("request::unmanage", function(c)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen ~= focused_screen then return end
		if c.fullscreen then
			wibar.visible = true
		end
	end)

	client.connect_signal("focus", function(c)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen ~= focused_screen then return end
		if c.fullscreen then
			wibar.visible = false
		else
			wibar.visible = true
		end
	end)

	client.connect_signal("unfocus", function(c)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen ~= focused_screen then return end
		if c.fullscreen then
			wibar.visible = true
		end
	end)

	client.connect_signal("property::minimized", function(c)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen ~= focused_screen then return end
		if c.fullscreen then
			wibar.visible = true
		end
	end)

	client.connect_signal("property::fullscreen", function(c)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen ~= focused_screen then return end
		if helpers.has_common_values(c:tags(), focused_screen.selected_tags) and c.fullscreen then
			wibar.visible = false
		else
			wibar.visible = true
		end
	end)
end

screen.connect_signal("request::desktop_decoration", function(s)
	if s == screen.primary then
		s.bar = bar.set_primary(s)
	else
		s.bar = bar.set_secondary(s)
	end

	set_wibar_hideaway(s.bar)
end)

naughty.connect_signal("request::display", function(n)
	notifications:display(n)
end)

screen.connect_signal("request::wallpaper", function(s)
	s.wallpaper = Wallpaper(s)

	if user.wallpaper then
		s.wallpaper:set(user.wallpaper)
	end
end)

client.connect_signal("request::titlebars", function(c)
	Titlebar(c)
end)

launcher:connect_signal("state", function(_, state)
	if state then
		powermenu:close()
		control:close()
		day_info:close()
		desktop_menu:hide()
	end
end)

powermenu:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		control:close()
		day_info:close()
		desktop_menu:hide()
	end
end)

control:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		powermenu:close()
		day_info:close()
		desktop_menu:hide()
	end
end)

day_info:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		powermenu:close()
		control:close()
		desktop_menu:hide()
	end
end)

local function click_hideaway()
	if client_menu._menu then
		client_menu._menu:hide()
	end
	desktop_menu:hide()
	launcher:close()
	powermenu:close()
	control:close()
	day_info:close()
end

awful.mouse.append_global_mousebinding(
	awful.button({}, 1, click_hideaway)
)

client.connect_signal("request::manage", function(c)
	c:connect_signal("button::press", click_hideaway)
end)

client.connect_signal("request::unmanage", function(c)
	c:disconnect_signal("button::press", click_hideaway)
end)
