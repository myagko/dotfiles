local awful = require("awful")
local User = require("user")

local Screenshot = require("daemons.screenshot")
local Powermenu = require("ui.powermenu")

local menuitem_awesome = {
    { "restart", function() awesome.restart() end },
    { "power", function() Powermenu:toggle() end }
}

local menuitem_shot = {
    { "full", function() Screenshot:full() end },
    { "full 5s", function() Screenshot:wait() end },
    { "area", function() Screenshot:select() end }
}

local mainmenu = awful.menu {
    auto_expand = true,
    items = {
        { "awesome", menuitem_awesome },
        { "shot", menuitem_shot },
        { "terminal", User.terminal },
        { "files", User.filemanager },
        { "web", User.webbrowser }
    }
}

return mainmenu
