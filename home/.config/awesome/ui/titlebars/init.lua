local awful = require("awful")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local widgets = require("widgets")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
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

	local close_button = widgets.hover_button {
		markup = text_icons.cross,
		forced_width = dpi(25),
		fg_normal = beautiful.fg_alt,
		bg_normal = beautiful.bg,
		fg_hover = beautiful.bg,
		bg_hover = beautiful.red,
		buttons = {
			awful.button({}, 1, function()
				c:kill()
			end)
		}
	}

	local maximize_button = widgets.hover_button {
		markup = c.maximized and text_icons.shrink or text_icons.stretch,
		forced_width = dpi(25),
		fg_normal = beautiful.fg_alt,
		bg_normal = beautiful.bg,
		fg_hover = beautiful.bg,
		bg_hover = beautiful.yellow,
		buttons = {
			awful.button({}, 1, function()
				c.maximized = not c.maximized
				c:raise()
			end)
		}
	}

	local minimize_button = widgets.hover_button {
		markup = text_icons.dash,
		forced_width = dpi(25),
		fg_normal = beautiful.fg_alt,
		bg_normal = beautiful.bg,
		fg_hover = beautiful.bg,
		bg_hover = beautiful.green,
		buttons = {
			awful.button({}, 1, function()
				gtimer.delayed_call(function()
					c.minimized = true
				end)
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
			margins = dpi(5),
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(5),
				minimize_button,
				maximize_button,
				close_button
			}
		}
	}

	c:connect_signal("property::maximized", function()
		if c.maximized then
			maximize_button:set_text(text_icons.shrink)
		else
			maximize_button:set_text(text_icons.stretch)
		end
	end)

	c:connect_signal("property::active", function()
		if c.active then
			close_button._private.fg_normal = beautiful.fg
			close_button.fg = beautiful.fg
			maximize_button._private.fg_normal = beautiful.fg
			maximize_button.fg = beautiful.fg
			minimize_button._private.fg_normal = beautiful.fg
			minimize_button.fg = beautiful.fg
		else
			close_button._private.fg_normal = beautiful.fg_alt
			close_button.fg = beautiful.fg_alt
			maximize_button._private.fg_normal = beautiful.fg_alt
			maximize_button.fg = beautiful.fg_alt
			minimize_button._private.fg_normal = beautiful.fg_alt
			minimize_button.fg = beautiful.fg_alt
		end
	end)
end
