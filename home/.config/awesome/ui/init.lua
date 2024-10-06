local awful = require("awful")
local launcher = require("ui.launcher")
local powermenu = require("ui.powermenu")
local control = require("ui.control")
local day_info = require("ui.day_info")
local menu = require("ui.menu")

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
