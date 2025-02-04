local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local widgets = require("widgets")
local helpers = require("helpers")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local notifications = {}
local instance = nil

awful.screen.connect_for_each_screen(function(s)
	s.notifications = {}
end)

local function get_preffered_position(n, screen)
	local placement = awful.placement.top_right(n.popup_widget, {
		honor_workarea = true,
		margins = beautiful.notification_margins
	})

	local x = placement.x
	local y = placement.y

	if #screen.notifications > 1 then
		local parent = screen.notifications[#screen.notifications - 1]
		y = parent.popup_widget.y + parent.popup_widget.height + beautiful.notification_spacing
	end

	return { x = x, y = y }
end

local function remove_notif(n, screen, reason)
	if n == nil or n.popup_widget == nil then return end
	reason = reason or naughty.notification_closed_reason.undefined
	helpers.remove_nonindex_value(screen.notifications, n)
	local destroyed_n_y = n.popup_widget.y
	local destroyed_n_height = n.popup_widget.height

	for _, notif in ipairs(screen.notifications) do
		if #screen.notifications > 0 and notif.popup_widget.y > destroyed_n_y then
			notif.popup_widget.y = notif.popup_widget.y - destroyed_n_height - beautiful.notification_spacing
		end
	end

	n.popup_widget.visible = false
	n.popup_widget = nil
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
			fg = n.urgency == "critical" and beautiful.red or beautiful.fg
		})
	}

	local ntitle = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(n.title, {
			fg = n.urgency == "critical" and beautiful.red or beautiful.fg
		})
	}

	local nicon = wibox.widget {
		widget = wibox.widget.imagebox,
		resize = true,
		halign = "center",
		valign = "center",
		image = n.icon
	}

	local ndismiss = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(text_icons.cross, { fg = beautiful.red })
	}

	ntitle:buttons {
		awful.button({}, 1, function()
			remove_notif(n, screen, naughty.notification_closed_reason.dismissed_by_user)
		end)
	}

	nmassage:buttons {
		awful.button({}, 1, function()
			remove_notif(n, screen, naughty.notification_closed_reason.dismissed_by_user)
		end)
	}

	nicon:buttons {
		awful.button({}, 1, function()
			remove_notif(n, screen, naughty.notification_closed_reason.dismissed_by_user)
		end)
	}

	ndismiss:buttons {
		awful.button({}, 1, function()
			remove_notif(n, screen, naughty.notification_closed_reason.silent)
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
				strategy = "max",
				height = dpi(85),
				width = dpi(85),
				nicon
			},
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.constraint,
						strategy = "max",
						width = dpi(150),
						height = dpi(25),
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

	n.popup_widget = awful.popup {
		screen = screen,
		visible = false,
		ontop = true,
		minimum_width = dpi(380),
		maximum_width = dpi(450),
		minimum_height = dpi(100),
		maximum_height = dpi(200),
		bg = beautiful.bg,
		fg = beautiful.fg,
		border_color = beautiful.border_color,
		border_width = beautiful.border_width,
		placement = function() return { 0, 0 } end,
		widget = main_widget
	}

	local pos = get_preffered_position(n, screen)
	n.popup_widget:geometry(pos)
	n.popup_widget.visible = true

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

	require("ui.notifications.screenshots")

	return ret
end

if not instance then
	instance = new()
end

return instance
