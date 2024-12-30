local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local widgets = require("widgets")
local helpers = require("helpers")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local screenshot_daemon = require("daemons.screenshot")

local notifications = {}
local instance = nil

awful.screen.connect_for_each_screen(function(s)
	s.notifications = {}
end)

local function get_preffered_position(n, screen)
	local placement = awful.placement.top_right(n.widget, {
		honor_workarea = true,
		margins = beautiful.notification_margins
	})

	local x = placement.x
	local y = placement.y

	if #screen.notifications > 1 then
		local parent = screen.notifications[#screen.notifications - 1]
		y = parent.widget.y + parent.widget.height + beautiful.notification_spacing
	end

	return { x = x, y = y }
end

local function remove_notif(n, screen, reason)
	if n == nil or n.widget == nil then return end
	reason = reason or naughty.notification_closed_reason.undefined
	helpers.remove_nonindex_value(screen.notifications, n)
	local destroyed_n_y = n.widget.y
	local destroyed_n_height = n.widget.height

	for _, notif in ipairs(screen.notifications) do
		if #screen.notifications > 0 and notif.widget.y > destroyed_n_y then
			notif.widget.y = notif.widget.y - destroyed_n_height - beautiful.notification_spacing
		end
	end

	n.widget.visible = false
	n.widget = nil
	n:destroy(reason)
end

local function actions_widget(n)
	if #n.actions == 0 then return nil end

	local actions = wibox.widget {
		layout = wibox.layout.flex.horizontal,
		spacing = dpi(5)
	}

	for _, action in ipairs(n.actions) do
		local button = widgets.hover_button {
			buttons = {
				awful.button({}, 1, function()
					action:invoke()
				end)
			},
			margins = dpi(5),
			font = beautiful.font_h0,
			markup = action.name
		}
		actions:add(button)
	end

	return actions
end

local function create_notification(n, screen)
	table.insert(screen.notifications, n)

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
		valign = "top",
		image = n.icon
	}

	local ndismiss = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(text_icons.cross, { fg = beautiful.red })
	}

	ndismiss:buttons {
		awful.button({}, 1, function()
			remove_notif(n, screen, naughty.notification_closed_reason.dismissed_by_user)
		end)
	}

	local main_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(20),
		{
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
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.scroll.horizontal,
						step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
						speed = dpi(50),
						ntitle
					},
					nil,
					ndismiss
				},
				widgets.separator {
					dir = "h",
					size = beautiful.sep_width
				},
				nmassage,
				actions_widget(n)
			}
		}
	}

	n.widget = awful.popup {
		screen = screen,
		visible = true,
		ontop = true,
		minimum_width = dpi(300),
		maximum_width = dpi(450),
		minimum_height = dpi(100),
		maximum_height = dpi(200),
		bg = beautiful.background,
		fg = beautiful.foreground,
		border_color = beautiful.border_color,
		border_width = beautiful.border_width,
		placement = function() return { 1, 1 } end,
		widget = main_widget
	}

	local pos = get_preffered_position(n, screen)
	n.widget:geometry(pos)

	local n_timeout = beautiful.notification_timeout or 5
	gtimer.start_new(n_timeout, function()
		remove_notif(n, screen, naughty.notification_closed_reason.expired)
	end)
end

function notifications:display(n)
	create_notification(n, awful.screen.focused())
end

function notifications:toggle_silent()
	self.silent = not self.silent
	if not self.silent then
		naughty.resume()
	else
		naughty.suspend()
	end
end

local function new()
	local ret = notifications

	ret.silent = false

	screenshot_daemon:connect_signal("saved", function(_, dir)
		local display_dir = dir:gsub(tostring(os.getenv("HOME")), "~")
		naughty.notification {
			title = "Screenshot",
			text = "Saved to: " .. display_dir,
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
