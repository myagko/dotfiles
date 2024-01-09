local naughty = require("naughty")
local beautiful = require("beautiful")

local Dnd = {}

Dnd.state = false

function Dnd:toggle()
	self.state = not self.state
	if not self.state then
		naughty.notification {
			title = "Notifications",
			text = "silent mode disabled"
		}
		naughty.resume()
	else
		naughty.notification {
			title = "Notifications",
			text = "silent mode enabled",
			icon = beautiful.icon_bell_off
		}
		naughty.suspend()
	end
end

return Dnd
