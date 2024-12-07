local naughty = require("naughty")
local wibox = require("wibox")
local rnotification = require("ruled.notification")
local widgets = require("widgets")
local helpers = require("helpers")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local screenshot_daemon = require("daemons.screenshot")

local notifications = {}
local instance = nil

function notifications:toggle_silent()
	self.silent = not self.silent
	if not self.silent then
		naughty.resume()
	else
		naughty.suspend()
	end
end

function notifications:display(n)
	if not n.icon then
		if n.urgency == "normal" then
			n.icon = beautiful.notification_icon_bell
		elseif n.urgency == "critical" then
			n.icon = beautiful.notification_icon_alert
		end
	end

	local nmassage = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup((n.text or n.massage), {
			fg = n.urgency == "critical" and beautiful.red or beautiful.foreground
		})
	}

	local ntitle = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(n.title, {
			fg = n.urgency == "critical" and beautiful.red or beautiful.foreground
		})
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
			widgets.separator {
				dir = "h",
				size = beautiful.sep_width
			},
			nmassage
		}
	}

	naughty.layout.box {
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
end

local function new()
	local ret = notifications

	ret.silent = false

	rnotification.append_rule {
		rule = { urgency = "normal" },
		properties = {
			screen = screen.primary,
			implicit_timeout = beautiful.notification_timeout
		}
	}

	rnotification.append_rule {
		rule = { urgency = "critical" },
		properties = {
			screen = screen.primary
		}
	}

	screenshot_daemon:connect_signal("saved", function(_, dir)
		naughty.notification {
			title = "Screenshot",
			text = "Saved to: " .. dir,
			icon = beautiful.notification_icon_camera
		}
	end)

	screenshot_daemon:connect_signal("canceled", function(_)
		naughty.notification {
			title = "Screenshot",
			text = "Canceled",
			icon = beautiful.notification_icon_camera
		}
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
