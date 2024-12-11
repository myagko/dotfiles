local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local user = require("user")

local screenshot_daemon = {}
local instance = nil

local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function screenshot_daemon:take(args)
	local name = os.date("%F-%H%M%S") .. ".png"
	local dir = os.getenv("HOME") .. "/" .. (string.match(user.screenshots_folder, "/$") and
		user.screenshots_folder or user.screenshots_folder .. "/")

	awful.spawn.easy_async_with_shell("maim " .. args .. " " .. dir .. name, function()
		if file_exists(dir .. name) then
			self:emit_signal("saved", dir)
		else
			self:emit_signal("canceled")
		end
	end)
end

function screenshot_daemon:full()
	self:take("-u")
end

function screenshot_daemon:wait(delay)
	delay = delay or 1
	self:take("-u -d " .. delay)
end

function screenshot_daemon:select()
	self:take("-s -u")
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, screenshot_daemon, true)

	return ret
end

if not instance then
	instance = new()
end

return instance
