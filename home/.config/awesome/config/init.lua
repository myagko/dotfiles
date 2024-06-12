local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local ruled = require("ruled")
local naughty = require("naughty")
local User = require("user")

beautiful.init("~/.config/awesome/themes/" .. User.theme .. "/theme.lua")

tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts {
        awful.layout.suit.floating,
        --awful.layout.suit.tile
    }
end)

local Bar = require("ui.bar")
local Walls = require("ui.walls")

for s in screen do
    awful.tag({ "tag_1", "tag_2", "tag_3", "tag_4", "tag_5" }, s, awful.layout.layouts[1])

    if s == screen.primary then
        s.bar = Bar:set_primary(s)
    else
        s.bar = Bar:set_secondary(s)
    end
    s.wall = Walls.set(s)
end

local Titlebars = require("ui.titlebars")
local Notifications = require("daemons.notifications")

ruled.notification.connect_signal('request::rules', function()
    Notifications:append_rules()
end)

naughty.connect_signal("request::display", function(n)
    Notifications:display(n)
end)

client.connect_signal("request::titlebars", function(c)
    Titlebars:create(c)
end)

require("config.rules")
require("config.binds")

require("daemons.pulse"):get_all()
require("daemons.wifi"):get_status()
require("daemons.bluetooth"):get_status()
require("daemons.weather"):set_remote_watch()

awful.spawn.with_shell("~/.config/awesome/autostart.sh")
