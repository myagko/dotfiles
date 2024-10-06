local naughty = require("naughty")
local beautiful = require("beautiful")
local screenshot_daemon = require("daemons.screenshot")

screenshot_daemon:connect_signal("screenshot::saved", function(_, dir)
	naughty.notification {
		title = "Screenshot",
		text = "Saved to: " .. dir,
		icon = beautiful.notification_icon_camera
	}
end)

screenshot_daemon:connect_signal("screenshot::canceled", function(_)
	naughty.notification {
		title = "Screenshot",
		text = "Canceled",
		icon = beautiful.notification_icon_camera
	}
end)
