local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local Titlebars = {}

function Titlebars:create(c)
	awful.titlebar.enable_tooltip = false

	local titlebar = awful.titlebar(c, {
		size = 35,
		position = "top"
	})

	local buttons = {
		awful.button({ }, 1, function()
			client.focus = c
			c:raise()
			awful.mouse.client.move(c)
		end),
		awful.button({ }, 3, function()
			client.focus = c
			c:raise()
			awful.mouse.client.resize(c)
		end)
	}

	local close = wibox.widget {
		widget = wibox.container.background,
		forced_width = 15,
		bg = beautiful.background_alt,
		buttons = {
			awful.button({}, 1, function()
				c:kill()
			end)
		}
	}

	local maximize = wibox.widget {
		widget = wibox.container.background,
		forced_width = 15,
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
		forced_width = 15,
		bg = beautiful.background_alt,
		buttons = {
			awful.button({}, 1, function()
				gears.timer.delayed_call(function()
					c.minimized = not c.minimized
				end)
			end)
		}
	}

	titlebar.widget = {
		layout = wibox.layout.align.horizontal,
		{
			widget = wibox.container.background,
			buttons = buttons,
		},
		{
			widget = wibox.container.background,
			buttons = buttons,
		},
		{
			widget = wibox.container.margin,
			margins = 10,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 10,
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

return Titlebars
