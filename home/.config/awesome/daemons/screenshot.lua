local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local default = require("user")

local Screenshot = {}

function Screenshot:take(args)
	local name = os.date("%F-%H%M%S") .. ".png"
	local dir = default.shotdir

	awful.spawn.easy_async_with_shell("maim " .. args .. " " .. dir .. name, function()
		awful.spawn.easy_async_with_shell("ls " .. dir .. " | grep -i " .. name, function(stdout)
			if stdout:match("%w+") then
				naughty.notification {
					title = "Screenshot",
					text = "Saved to " .. dir,
					icon = beautiful.icon_photo
				}
			else
				naughty.notification {
					title = "Screenshot",
					text = "Cancelled",
					icon = beautiful.icon_photo
				}
			end
		end)
	end)
end

function Screenshot:full()
	self:take("-u")
end

function Screenshot:wait()
	self:take("-u -d 5")
end

function Screenshot:select()
	self:take("-s -u")
end

return Screenshot
