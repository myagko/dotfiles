local awful = require("awful")
local beautiful = require("beautiful")
local user = require("user")
local dpi = beautiful.xresources.apply_dpi
local screenshot_daemon = require("daemons.screenshot")
local powermenu = require("ui.powermenu")

local menu = awful.menu {
	auto_expand = true,
	theme = {
		font = beautiful.font_h1,
		width = dpi(150),
		height = dpi(30)
	},
	items = {
		{ "awesome", {
			{ "restart", function() awesome.restart() end },
			{ "power", function() powermenu:toggle() end },
		}},
		{ "shot", {
			{ "full", function() screenshot_daemon:full() end },
			{ "full 5s", function() screenshot_daemon:wait(5) end },
			{ "area", function() screenshot_daemon:select() end }
		}},
		{ "terminal", user.terminal },
		{ "files", user.filemanager },
		{ "web", user.webbrowser }
	}
}

return menu
