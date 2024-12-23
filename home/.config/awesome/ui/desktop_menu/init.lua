local awful = require("awful")
local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local user = require("user")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local screenshot_daemon = require("daemons.screenshot")
local powermenu = require("ui.powermenu")

local function changetheme(newtheme)
	user.theme = newtheme
	helpers.table_to_file(gfilesystem.get_configuration_dir() .. "/user.lua", user)
	awesome.restart()
end

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
			{ "theme", {
				{ "gruvbox", function() changetheme("gruvbox") end },
				{ "everblush", function() changetheme("everblush") end },
				{ "haven", function() changetheme("haven") end },
				{ "nymph", function() changetheme("nymph") end }
			}}
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
