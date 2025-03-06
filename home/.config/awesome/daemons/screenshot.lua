local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local Gdk = lgi.require("Gdk", "3.0")
local GdkPixbuf = lgi.GdkPixbuf
local awful = require("awful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local user = require("user")
local file_exists = require("helpers").file_exists

local screenshot_daemon = {}
local instance = nil

function screenshot_daemon:take(args)
	local name = os.date("%F-%H%M%S") .. ".png"
	local dir = (string.match(user.screenshots_folder, "/$") and
		user.screenshots_folder or user.screenshots_folder .. "/")

	awful.spawn.easy_async_with_shell("maim " .. args .. " " .. dir .. name, function()
		if file_exists(dir .. name) then
			self:emit_signal("saved", dir, name)
		else
			self:emit_signal("canceled")
		end
	end)
end

function screenshot_daemon:take_full()
	self:take("-u")
end

function screenshot_daemon:take_delay(delay)
	delay = delay or 1
	self:take("-u -d " .. delay)
end

function screenshot_daemon:take_select()
	self:take("-s -u")
end

function screenshot_daemon:copy_screenshot(path)
	local image = GdkPixbuf.Pixbuf.new_from_file(path)
	if image then
		self._private.clipboard:set_image(image)
		self._private.clipboard:store()
	end
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, screenshot_daemon, true)
	ret._private = {}

	ret._private.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)

	return ret
end

if not instance then
	instance = new()
end

return instance
