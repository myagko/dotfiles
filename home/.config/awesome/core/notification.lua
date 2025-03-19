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

capi.awesome.connect_signal("request::restart", function()
	naughty.destroy_all_notifications(nil, naughty.notification_closed_reason.silent)
end)
