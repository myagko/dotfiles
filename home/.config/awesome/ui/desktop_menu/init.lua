local Gio = require("lgi").Gio
local awful = require("awful")
local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local dpi = beautiful.xresources.apply_dpi
local screenshot_daemon = require("daemons.screenshot")
local powermenu = require("ui.powermenu")
local user = require("user")

local menu = awful.menu {
	auto_expand = true,
	theme = {
		font = beautiful.font_h0,
		width = dpi(180),
		height = dpi(25)
	},
	items = {
		{ "awesome", {
			{ "config", function() awful.spawn("xdg-open " .. gfilesystem.get_configuration_dir()) end },
			{ "restart", function() awesome.restart() end },
			{ "power", function() powermenu:toggle() end }
		} },
		{ "take screenshot", {
			{ "full", function() screenshot_daemon:take_full() end },
			{ "full 5s delay", function() screenshot_daemon:take_delay(5) end },
			{ "select area", function() screenshot_daemon:take_select() end }
		} },
		{ "terminal", function() awful.spawn(user.terminal) end },
		{ "home files", function() awful.spawn("xdg-open " .. os.getenv("HOME")) end },
		{ "webbrowser", function()
			local app = Gio.AppInfo.get_default_for_type("text/html")
			app:launch()
		end }
	}
}

return menu
