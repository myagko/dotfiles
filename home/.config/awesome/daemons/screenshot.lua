local awful = require("awful")
local gears = require("gears")
local user = require("user")

local screenshot_daemon = {}
local instance = nil

function screenshot_daemon:take(args)
	local name = os.date("%F-%H%M%S") .. ".png"
	local shot_dir = user.shot_dir or "~"

	local dir = string.match(shot_dir, "%/$") and shot_dir or shot_dir .. "/"

	awful.spawn.easy_async_with_shell("maim " .. args .. " " .. dir .. name, function()
		awful.spawn.easy_async_with_shell("ls " .. dir .. " | grep -i " .. name, function(stdout)
			if stdout:match("%w+") then
				self:emit_signal("screenshot::saved", dir)
			else
				self:emit_signal("screenshot::canceled")
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

local function new()
	local ret = gears.object {}
	gears.table.crush(ret, screenshot_daemon, true)

	return ret
end

if not instance then
	instance = new()
end

return instance
