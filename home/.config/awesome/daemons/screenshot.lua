local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local helpers = require("helpers")
local user = require("user")

local screenshot_daemon = {}
local instance = nil

function screenshot_daemon:take(args)
	local name = os.date("%F-%H%M%S") .. ".png"
	local shot_dir = user.shot_dir or "~"
	local dir = string.match(shot_dir, "%/$") and shot_dir or shot_dir .. "/"

	awful.spawn.easy_async_with_shell("maim " .. args .. " " .. dir .. name, function()
		awful.spawn.easy_async_with_shell("ls " .. dir, function(stdout)
			if stdout:match(helpers.lua_escape(name)) then
				self:emit_signal("saved", dir)
			else
				self:emit_signal("canceled")
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
	local ret = gobject {}
	gtable.crush(ret, screenshot_daemon, true)

	return ret
end

if not instance then
	instance = new()
end

return instance
