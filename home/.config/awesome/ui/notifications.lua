local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local ruled = require("ruled")
local helpers = require("helpers")

local Notifs = {}

function Notifs:append_rules()
	ruled.notification.append_rule {
		rule = { urgency = "normal" },
		properties = {
			screen = awful.screen.preferred,
			implicit_timeout = 5,
			position = "top_right"
		}
	}
	ruled.notification.append_rule {
		rule = { urgency = "critical" },
		properties = {
			screen = awful.screen.preferred,
			position = "top_right",
			icon = beautiful.icon_alert
		}
	}
end

function Notifs:display(n)
	if not n.icon then
		n.icon = beautiful.icon_bell
	end

	local nsep = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_urgent,
		forced_height = beautiful.sep_width
	}

	local nmassage = wibox.widget {
		widget = wibox.widget.textbox,
		font = helpers:inc_fontsize(-1.5),
		markup = n.massage or n.text
	}

	local ntitle = wibox.widget {
		widget = wibox.widget.textbox,
		font = helpers:inc_fontsize(2),
		markup = n.title
	}

	local nicon = wibox.widget {
		widget = wibox.widget.imagebox,
		resize = true,
		halign = "center",
		valign = "center",
		image = n.icon
	}

	local main_widget = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		fill_space = true,
		spacing = 20,
		{
			widget = wibox.container.constraint,
			height = 65,
			width = 65,
			strategy = "max",
			nicon
		},
		{
			layout = wibox.layout.fixed.vertical,
			spacing = 5,
			{
				widget = wibox.container.scroll.horizontal,
				step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
				speed = 50,
				ntitle
			},
			nsep,
			nmassage
		}
	}

	local npopup = naughty.layout.box {
		notification = n,
		maximum_width = 380,
		minimum_width = 300,
		maximum_height = 150,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		widget_template = {
			widget = wibox.container.background,
			{
				widget = wibox.container.margin,
				margins = 20,
				main_widget
			}
		}
	}

	if n.urgency == "critical" then
		npopup.fg = beautiful.red
	end
end

return Notifs
