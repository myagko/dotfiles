collectgarbage("incremental", 110, 1000)
pcall(require, "luarocks.loader")

local memory_last_check_count = collectgarbage("count")
local memory_last_run_time = os.time()
local memory_growth_factor = 1.1
local memory_long_collection_time = 300

require("gears.timer").start_new(5, function()
	local cur_memory = collectgarbage("count")
	local elapsed = os.time() - memory_last_run_time
	local waited_long = elapsed >= memory_long_collection_time
	local grew_enough = cur_memory > (memory_last_check_count * memory_growth_factor)
	if grew_enough or waited_long then
		collectgarbage("collect")
		collectgarbage("collect")
		memory_last_run_time = os.time()
	end
	memory_last_check_count = collectgarbage("count")
	return true
end)

local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local ruled = require("ruled")
local naughty = require("naughty")
local User = require("user")

naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification {
		urgency = "critical",
		title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
		message = message
	}
end)

beautiful.init("~/.config/awesome/themes/" .. User.theme .. "/theme.lua")

tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts {
		awful.layout.suit.floating,
		--awful.layout.suit.tile
	}
end)

local Bar = require("ui.bar")
local Wallpaper = require("ui.wallpaper")

for s in screen do
	awful.tag({ "tag_1", "tag_2", "tag_3", "tag_4", "tag_5" }, s, awful.layout.layouts[1])

	if s == screen.primary then
		s.bar = Bar:set_primary(s)
	else
		s.bar = Bar:set_secondary(s)
	end

	s.wall = Wallpaper.create(s)
	s.wall:set(User.wall or beautiful.wallpaper)
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

require("ui")
require("config.rules")
require("config.binds")
require("daemons.pulse"):get_all()
require("daemons.weather"):set_remote_watch()
require("autostart")
