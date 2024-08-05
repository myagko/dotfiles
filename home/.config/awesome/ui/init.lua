local awful = require("awful")

local Launcher = require("ui.launcher")
local Powermenu = require("ui.powermenu")
local Control = require("ui.control")
local Day_info = require("ui.day_info")
local Menu = require("ui.menu")

awesome.connect_signal("powermenu:state", function(state)
	if state then Launcher:close() end
end)

awesome.connect_signal("control:state", function(state)
	if state then Launcher:close() end
end)

awesome.connect_signal("day_info:state", function(state)
	if state then Launcher:close() end
end)

awesome.connect_signal("launcher:state", function(state)
	if state then Powermenu:close() end
end)

awesome.connect_signal("control:state", function(state)
	if state then Powermenu:close() end
end)

awesome.connect_signal("day_info:state", function(state)
	if state then Powermenu:close() end
end)

awesome.connect_signal("launcher:state", function(state)
	if state then Control:close() end
end)

awesome.connect_signal("powermenu:state", function(state)
	if state then Control:close() end
end)

awesome.connect_signal("day_info:state", function(state)
	if state then Control:close() end
end)

awesome.connect_signal("launcher:state", function(state)
	if state then Day_info:close() end
end)

awesome.connect_signal("powermenu:state", function(state)
	if state then Day_info:close() end
end)

awesome.connect_signal("control:state", function(state)
	if state then Day_info:close() end
end)

client.connect_signal("button::press", function()
	Menu:hide()
	Launcher:close()
	Powermenu:close()
	Control:close()
	Day_info:close()
end)


awful.mouse.append_global_mousebinding(
	awful.button({}, 1, function()
		Menu:hide()
		Launcher:close()
		Powermenu:close()
		Control:close()
		Day_info:close()
	end)
)
