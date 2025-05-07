local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local user = require("user")
local has_common = require("helpers").has_common
local capi = { screen = screen, client = client }
local titlebar = require("ui.titlebar")
local wallpaper = require("ui.wallpaper")
local bar = require("ui.bar")
local menu = require("ui.menu").get_default()
local notifications = require("ui.notifications").get_default()
local launcher = require("ui.launcher").get_default()
local powermenu = require("ui.powermenu").get_default()
local control_panel = require("ui.control_panel").get_default()
local day_info_panel = require("ui.day_info_panel").get_default()

local function set_wibar_hideaway(wibar)
	local function hide_wibar(client)
		local focused_screen = awful.screen.focused({ client = true })
		if wibar.screen == focused_screen
		and has_common(client:tags(), focused_screen.selected_tags) then
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

	capi.client.connect_signal("request::manage", function(c)
		hide_wibar(c)
	end)

	capi.client.connect_signal("focus", function(c)
		hide_wibar(c)
	end)

	capi.client.connect_signal("property::fullscreen", function(c)
		hide_wibar(c)
	end)

	capi.client.connect_signal("request::unmanage", function(c)
		show_wibar(c)
	end)

	capi.client.connect_signal("unfocus", function(c)
		show_wibar(c)
	end)

	capi.client.connect_signal("property::minimized", function(c)
		show_wibar(c)
	end)
end

capi.screen.connect_signal("request::desktop_decoration", function(s)
	if s == screen.primary then
		s.bar = bar.create_primary(s)
		s.bar:connect_signal("property::visible", function()
			if control_panel.state == true then
				awful.placement.bottom_right(control_panel.popup_widget, {
					honor_workarea = true,
					margins = beautiful.useless_gap
				})
			end

			if day_info_panel.state == true then
				awful.placement.bottom_right(day_info_panel.popup_widget, {
					honor_workarea = true,
					margins = beautiful.useless_gap
				})
			end

			if launcher.state == true then
				awful.placement.bottom_left(launcher.popup_widget, {
					honor_workarea = true,
					margins = beautiful.useless_gap
				})
			end
		end)
	else
		s.bar = bar.create_secondary(s)
	end

	set_wibar_hideaway(s.bar)
end)

capi.screen.connect_signal("request::wallpaper", function(s)
	s.wallpaper = wallpaper(s)

	if user.wallpaper then
		s.wallpaper:set_image(user.wallpaper)
	end
end)

capi.client.connect_signal("request::titlebars", function(c)
	titlebar(c)
end)

naughty.connect_signal("request::display", function(n)
	notifications.display(n)
end)

powermenu:connect_signal("state", function(_, state)
	if state == true then
		launcher:close()
		control_panel:close()
		day_info_panel:close()
		menu:hide()
	end
end)

launcher:connect_signal("state", function(_, state)
	if state == true then
		powermenu:close()
		menu:hide()
	end
end)

control_panel:connect_signal("state", function(_, state)
	if state == true then
		powermenu:close()
		day_info_panel:close()
		menu:hide()
	end
end)

day_info_panel:connect_signal("state", function(_, state)
	if state == true then
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

capi.client.connect_signal("request::manage", function(c)
	c:connect_signal("button::press", click_hideaway)
end)
