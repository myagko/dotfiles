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
local control_panel = require("ui.control_panel")
local day_info_panel = require("ui.day_info_panel")
local menu = require("ui.menu")

local function set_wibar_hideaway(wibar)
	local function hide_wibar(client)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen == focused_screen and
		helpers.has_common_values(client:tags(), focused_screen.selected_tags) then
			if client.fullscreen then
				wibar.visible = false
			else
				wibar.visible = true
			end
		end
	end

	local function show_wibar(client)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen == focused_screen then
			if client.fullscreen then
				wibar.visible = true
			end
		end
	end

	client.connect_signal("request::manage", function(c)
		hide_wibar(c)
	end)

	client.connect_signal("focus", function(c)
		hide_wibar(c)
	end)

	client.connect_signal("property::fullscreen", function(c)
		hide_wibar(c)
	end)

	client.connect_signal("request::unmanage", function(c)
		show_wibar(c)
	end)

	client.connect_signal("unfocus", function(c)
		show_wibar(c)
	end)

	client.connect_signal("property::minimized", function(c)
		show_wibar(c)
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
		s.wallpaper:set(user.wallpaper, true)
	end
end)

client.connect_signal("request::titlebars", function(c)
	Titlebar(c)
end)

powermenu:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		control_panel:close()
		day_info_panel:close()
		menu:hide()
	end
end)

launcher:connect_signal("state", function(_, state)
	if state then
		powermenu:close()
		menu:hide()
	end
end)

control_panel:connect_signal("state", function(_, state)
	if state then
		powermenu:close()
		day_info_panel:close()
		menu:hide()
	end
end)

day_info_panel:connect_signal("state", function(_, state)
	if state then
		powermenu:close()
		control_panel:close()
		menu:hide()
	end
end)

local function click_hideaway()
	menu:hide()
	launcher:close()
	powermenu:close()
	control_panel:close()
	day_info_panel:close()
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
