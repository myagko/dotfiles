local naughty = require("naughty")
local rnotification = require("ruled.notification")
local capi = { awesome = awesome }

rnotification.connect_signal("request::rules", function()
	rnotification.append_rule {
		id = "global",
		rule = {},
		properties = { timeout = 0 }
	}
end)

naughty.connect_signal("request::display_error", function(message, startup)
	naughty.notification {
		app_name = "Awesome",
		urgency = "critical",
		title = "An error happened" .. (startup and " during startup!" or "!"),
		message = message
	}
end)

capi.awesome.connect_signal("request::restart", function()
	naughty.destroy_all_notifications(nil, naughty.notification_closed_reason.silent)
end)
