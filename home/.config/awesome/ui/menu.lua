local awful = require("awful")
local user = require("user")
local screenshot_daemon = require("daemons.screenshot")
local powermenu = require("ui.powermenu")

local menuitem_awesome = {
	{ "restart", function() awesome.restart() end },
	{ "power", function() powermenu:toggle() end }
}

local menuitem_shot = {
	{ "full", function() screenshot_daemon:full() end },
	{ "full 5s", function() screenshot_daemon:wait() end },
	{ "area", function() screenshot_daemon:select() end }
}

local mainmenu = awful.menu {
	auto_expand = true,
	items = {
		{ "awesome", menuitem_awesome },
		{ "shot", menuitem_shot },
		{ "terminal", user.terminal },
		{ "files", user.filemanager },
		{ "web", user.webbrowser }
	}
}

return mainmenu
