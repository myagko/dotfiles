local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local ruled = require("ruled")
local helpers = require("helpers")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local notifications = {}

notifications.silent = false

function notifications:toggle_silent()
	self.silent = not self.silent
	if not self.silent then
		naughty.resume()
	else
		naughty.suspend()
	end
end

function notifications:append_rules()
	ruled.notification.append_rule {
		rule = { urgency = "normal" },
		properties = {
			screen = awful.screen.preferred,
			implicit_timeout = beautiful.notification_timeout,
			position = beautiful.notification_position
		}
	}
	ruled.notification.append_rule {
		rule = { urgency = "critical" },
		properties = {
			screen = awful.screen.preferred,
			implicit_timeout = beautiful.notification_timeout,
			position = beautiful.notification_position,
			icon = beautiful.notification_icon_alert
		}
	}
end

function notifications:display(n)
	if not n.icon and n.urgency ~= "critical" then
		n.icon = beautiful.notification_icon_bell
	end

	local nmassage = wibox.widget {
		widget = wibox.widget.textbox,
		markup = n.massage or n.text
	}

	local ntitle = wibox.widget {
		widget = wibox.widget.textbox,
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
		spacing = dpi(20),
		{
			widget = wibox.container.constraint,
			height = dpi(65),
			width = dpi(65),
			strategy = "max",
			nicon
		},
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(5),
			{
				widget = wibox.container.scroll.horizontal,
				step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
				speed = dpi(50),
				ntitle
			},
			helpers.ui.create_sep { orientation = "h", size = beautiful.sep_width },
			nmassage
		}
	}

	local npopup = naughty.layout.box {
		notification = n,
		maximum_width = beautiful.notification_max_width,
		minimum_width = beautiful.notification_min_width,
		maximum_height = beautiful.notification_max_height,
		minimum_height = beautiful.notification_min_height,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		widget_template = {
			widget = wibox.container.background,
			{
				widget = wibox.container.margin,
				margins = dpi(20),
				main_widget
			}
		}
	}

	if n.urgency == "critical" then
		npopup.fg = beautiful.red
	end
end

return notifications
