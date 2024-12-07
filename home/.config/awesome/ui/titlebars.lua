local awful = require("awful")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local client_menu = require("ui.client_menu")

return function(c)
	if c.requests_no_titlebar then return end
	awful.titlebar.enable_tooltip = false

	local titlebar = awful.titlebar(c, {
		size = dpi(35),
		position = "top"
	})

	local buttons = {
		awful.button({}, 1, function()
			client.focus = c
			c:raise()
			awful.mouse.client.move(c)
		end),
		awful.button({}, 2, function()
			client_menu:toggle(c)
		end),
		awful.button({}, 3, function()
			client.focus = c
			c:raise()
			awful.mouse.client.resize(c)
		end)
	}

	local maximize = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(15),
		bg = beautiful.background_alt,
		buttons = {
			awful.button({}, 1, function()
				c.maximized = not c.maximized
				c:raise()
			end)
		}
	}

	local minimize = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(15),
		bg = beautiful.background_alt,
		buttons = {
			awful.button({}, 1, function()
				gtimer.delayed_call(function()
					c.minimized = true
				end)
			end)
		}
	}

	local close = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(15),
		bg = beautiful.background_alt,
		buttons = {
			awful.button({}, 1, function()
				c:kill()
			end)
		}
	}

	titlebar.widget = {
		layout = wibox.layout.align.horizontal,
		{
			widget = wibox.container.background,
			buttons = buttons
		},
		{
			widget = wibox.container.background,
			buttons = buttons
		},
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(10),
				maximize,
				minimize,
				close
			}
		}
	}

	c:connect_signal("property::active", function()
		if c.active then
			close.bg = beautiful.red
			minimize.bg = beautiful.yellow
			maximize.bg = beautiful.green
		else
			close.bg = beautiful.background_alt
			minimize.bg = beautiful.background_alt
			maximize.bg = beautiful.background_alt
		end
	end)
end
