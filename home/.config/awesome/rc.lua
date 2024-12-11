pcall(require, "luarocks.loader")
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)

local naughty = require("naughty")

naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification {
		urgency = "critical",
		title = "An error happened" .. (startup and " during startup!" or "!"),
		message = message
	}
end)

require("config.theme")
require("config.tags")
require("ui")
require("config.rules")
require("config.binds")
