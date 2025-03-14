local awful = require("awful")
local naughty = require("naughty")
local screenshot = require("services.screenshot")

screenshot:connect_signal("saved", function(_, dir, name)
	local view_file = naughty.action { name = "View" }
	local open_dir = naughty.action { name = "Folder" }
	local copy = naughty.action { name = "Copy" }

	view_file:connect_signal("invoked", function()
		awful.spawn("xdg-open " .. dir .. name, false)
	end)

	open_dir:connect_signal("invoked", function()
		awful.spawn("xdg-open " .. dir, false)
	end)

	copy:connect_signal("invoked", function()
		screenshot:copy_screenshot(dir .. name)
	end)

	local display_dir = dir:gsub(tostring(os.getenv("HOME")), "~")

	naughty.notification {
		app_name = "Screenshot",
		title = "Screenshot taken",
		text = display_dir,
		icon = dir .. name,
		actions = { view_file, open_dir, copy }
	}
end)
