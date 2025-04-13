local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gtimer = require("gears.timer")
local common = require("common")
local beautiful = require("beautiful")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi
local create_markup = require("helpers").create_markup
local remove_nonindex_value = require("helpers").remove_nonindex_value

local notifications = {}
local instance = nil

awful.screen.connect_for_each_screen(function(s)
	s.notifications = {}
end)

local function update_positions(screen)
	if #screen.notifications > 0 then
		for i = 1, #screen.notifications do
			screen.notifications[i]:geometry({
				x = screen.workarea.width - beautiful.notification_margins
					- screen.notifications[i].width,
				y = i > 1 and screen.notifications[i - 1].y
					+ screen.notifications[i - 1].height + beautiful.notification_spacing
					or screen.workarea.y + beautiful.notification_margins
			})
		end
	end
end

local function add_popup(popup, screen)
	if not popup then return end
	table.insert(screen.notifications, 1, popup)
	update_positions(screen)
	popup.visible = true
end

local function remove_popup(popup, screen)
	if not popup then return end
	remove_nonindex_value(screen.notifications, popup)
	update_positions(screen)
	popup.visible = false
	popup = nil
end

local function create_actions_widget(n)
	if #n.actions == 0 then return nil end

	local actions_layout = wibox.widget {
		layout = wibox.layout.flex.horizontal,
		spacing = dpi(5)
	}

	local actions_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = { top = dpi(5) },
		actions_layout
	}

	for _, action in ipairs(n.actions) do
		local button = common.hover_button {
			buttons = {
				awful.button({}, 1, function()
					action:invoke()
				end)
			},
			margins = dpi(5),
			shape = beautiful.rrect(dpi(8)),
			markup = action.name
		}
		actions_layout:add(button)
	end

	return actions_widget
end

local function create_notification_popup(n)
	local name = wibox.widget {
		widget = wibox.widget.textbox,
		markup = create_markup(n.app_name, {
			fg = n.urgency == "critical" and beautiful.red or beautiful.fg
		})
	}

	local title = wibox.widget {
		widget = wibox.widget.textbox,
		markup = n.title
	}

	local massage = wibox.widget {
		widget = wibox.widget.textbox,
		font = beautiful.font_h0,
		markup = n.text or n.massage
	}

	local icon = wibox.widget {
		widget = wibox.widget.imagebox,
		resize = true,
		halign = "center",
		valign = "center",
		clip_shape = beautiful.rrect(dpi(5)),
		image = n.icon
	}

	local time = wibox.widget {
		widget = wibox.widget.textbox,
		markup = create_markup(os.date("%H:%M"), { fg = beautiful.fg_alt })
	}

	local close = wibox.widget {
		widget = wibox.widget.textbox,
		markup = create_markup(text_icons.cross, { fg = beautiful.red })
	}

	local main_widget = wibox.widget {
		widget = wibox.container.margin,
		margins = dpi(15),
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
					name
				},
				nil,
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(10),
					time,
					close
				}
			},
			{
				widget = wibox.container.background,
				forced_width = 1,
				forced_height = beautiful.separator_thickness,
				{
					widget = wibox.widget.separator,
					orientation = "horizontal"
				}
			},
			{
				layout = wibox.layout.fixed.horizontal,
				buttons = {
					awful.button({}, 1, function()
						n:destroy(naughty.notification_closed_reason.dismissed_by_user)
					end)
				},
				fill_space = true,
				spacing = dpi(10),
				{
					widget = wibox.container.constraint,
					strategy = "max",
					width = dpi(70),
					height = dpi(70),
					icon
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					{
						widget = wibox.container.constraint,
						strategy = "max",
						height = dpi(25),
						title
					},
					{
						widget = wibox.container.constraint,
						strategy = "max",
						height = dpi(70),
						massage
					}
				}
			},
			create_actions_widget(n)
		}
	}

	local popup_widget = awful.popup {
		screen = n.screen,
		visible = false,
		ontop = true,
		minimum_width = dpi(380),
		maximum_width = dpi(450),
		minimum_height = dpi(100),
		maximum_height = dpi(280),
		bg = beautiful.bg,
		fg = beautiful.fg,
		border_color = beautiful.border_color_normal,
		border_width = beautiful.border_width,
		shape = beautiful.rrect(dpi(22)),
		placement = function() return { 0, 0 } end,
		widget = main_widget
	}

	close:buttons {
		awful.button({}, 1, function()
			n:destroy(naughty.notification_closed_reason.silent)
		end)
	}

	return popup_widget
end

function notifications:display(n)
	local notification_popup = create_notification_popup(n)
	local display_timer = gtimer {
		timeout = beautiful.notification_timeout or 5,
		callback = function()
			remove_popup(notification_popup, n.screen)
		end
	}

	add_popup(notification_popup, n.screen)

	n:connect_signal("destroyed", function()
		display_timer:stop()
		display_timer = nil
		remove_popup(notification_popup, n.screen)
	end)

	if display_timer then
		display_timer:start()
	end
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
