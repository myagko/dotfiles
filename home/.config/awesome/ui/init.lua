local awful = require("awful")
local launcher = require("ui.launcher")
local powermenu = require("ui.powermenu")
local control = require("ui.control")
local day_info = require("ui.day_info")
local menu = require("ui.menu")

local function set_wibar_hideaway(wibar)
	client.connect_signal("focus", function(c)
		if c.fullscreen then
			wibar.visible = false
		else
			wibar.visible = true
		end
	end)

	client.connect_signal("unfocus", function(c)
		if c.fullscreen then
			wibar.visible = true
		end
	end)

	client.connect_signal("request::manage", function(c)
		if c.fullscreen then
			wibar.visible = false
		else
			wibar.visible = true
		end
	end)

	client.connect_signal("request::unmanage", function(c)
		if c.fullscreen then
			wibar.visible = true
		end
	end)

	client.connect_signal("property::fullscreen", function(c)
		if c.fullscreen then
			wibar.visible = false
		else
			wibar.visible = true
		end
	end)

	client.connect_signal("property::minimized", function(c)
		if c.fullscreen then
			wibar.visible = true
		end
	end)
end

for s in screen do
	set_wibar_hideaway(s.bar)
end

launcher:connect_signal("state", function(_, state)
	if state then
		powermenu:close()
		control:close()
		day_info:close()
	end
end)

powermenu:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		control:close()
		day_info:close()
	end
end)

control:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		powermenu:close()
		day_info:close()
	end
end)

day_info:connect_signal("state", function(_, state)
	if state then
		launcher:close()
		powermenu:close()
		control:close()
	end
end)

client.connect_signal("button::press", function()
	menu:hide()
	launcher:close()
	powermenu:close()
	control:close()
	day_info:close()
end)


awful.mouse.append_global_mousebinding(
	awful.button({}, 1, function()
		menu:hide()
		launcher:close()
		powermenu:close()
		control:close()
		day_info:close()
	end)
)

require("ui.notifications")
