local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local default = require("user")

local screenshot_daemon = {}

function screenshot_daemon:take(args)
	local name = os.date("%F-%H%M%S") .. ".png"
	local shot_dir = default.shot_dir

	local dir = string.match(shot_dir, "%/$") and shot_dir or shot_dir .. "/"

	awful.spawn.easy_async_with_shell("maim " .. args .. " " .. dir .. name, function()
		awful.spawn.easy_async_with_shell("ls " .. dir .. " | grep -i " .. name, function(stdout)
			if stdout:match("%w+") then
				naughty.notification {
					title = "Screenshot",
					text = "Saved to " .. dir,
					icon = beautiful.notification_icon_camera
				}
			else
				naughty.notification {
					title = "Screenshot",
					text = "Cancelled",
					icon = beautiful.notification_icon_camera
				}
			end
		end)
	end)
end

function screenshot_daemon:full()
	self:take("-u")
end

function screenshot_daemon:wait()
	self:take("-u -d 5")
end

function screenshot_daemon:select()
	self:take("-s -u")
end

return screenshot_daemon
