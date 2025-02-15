pcall(require, "luarocks.loader")
package.path = ".config/astal/?.lua;.config/astal/?/init.lua;" .. package.path

local astal = require("astal")
local gtkApp = require("astal.gtk3.app")
local src = require("lib").src

local Bar = require("widgets.bar")
local Notifications = require("widgets.notifications")
local Launcher = require("widgets.launcher")

local scss = src("style.scss")
local css = "/tmp/style.css"

astal.exec("sass " .. scss .. " " .. css)

gtkApp:start {
	instance_name = "astal-lua",
	css = css,
	main = function()
		for _, monitor in pairs(gtkApp.monitors) do
			Bar(monitor)
			Notifications(monitor)
		end
		Launcher()
	end
}
