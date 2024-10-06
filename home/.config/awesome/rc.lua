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

local naughty = require("naughty")

naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification {
		urgency = "critical",
		title = "An error happened" .. (startup and " during startup!" or "!"),
		message = message
	}
end)

local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local user = require("user")

beautiful.init("~/.config/awesome/themes/" .. (user.theme or "nymph") .. "/theme.lua")

local notifications_daemon = require("daemons.notifications")
local Bar = require("ui.bar")
local Titlebar = require("ui.titlebars")
local Wallpaper = require("ui.wallpaper")

naughty.connect_signal("request::display", function(n)
	notifications_daemon:display(n)
end)

client.connect_signal("request::titlebars", function(c)
	Titlebar(c)
end)

tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts {
		awful.layout.suit.floating,
		awful.layout.suit.tile,
	}
end)

for s in screen do
	awful.tag({ "tag_1", "tag_2", "tag_3", "tag_4", "tag_5" }, s, awful.layout.layouts[1])

	if s == screen.primary then
		s.bar = Bar:set_primary(s)
	else
		s.bar = Bar:set_secondary(s)
	end

	s.wallpaper = Wallpaper(s)

	if user.wallpaper then
		s.wallpaper:set_image(user.wallpaper)
	end
end

require("ui")
require("config.rules")
require("config.binds")
require("helpers.util").spawn_once(require("autostart"))
