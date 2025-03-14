local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local widgets = require("widgets")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi
local create_markup = require("helpers").create_markup

local notifications = require("ui.notifications")

local notification_list = {}
local instance = nil

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
		local button = widgets.hover_button {
			buttons = {
				awful.button({}, 1, function()
					action:invoke()
				end)
			},
			margins = dpi(5),
			bg_normal = beautiful.bg_urg,
			markup = action.name
		}
		actions_layout:add(button)
	end

	return actions_widget
end

local function create_notification_widget(n)
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

	local widget = wibox.widget {
		widget = wibox.container.constraint,
		strategy = "max",
		height = 260,
		{
			widget = wibox.container.background,
			bg = beautiful.bg_alt,
			{
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
					widgets.separator {
						vertical = true,
						size = beautiful.sep_width
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
								height = dpi(80),
								massage
							}
						}
					},
					create_actions_widget(n)
				}
			}
		}
	}

	close:buttons {
		awful.button({}, 1, function()
			n:destroy(naughty.notification_closed_reason.silent)
		end)
	}

	return widget
end

local function remove_notification(w, self)
	local notifs_layout = self.main_widget:get_children_by_id("notifs_layout")[1]
	notifs_layout:remove_widgets(w)
	if #notifs_layout.children == 0 then
		notifs_layout:insert(1, self.empty_massage)
		self.is_empty = true
	end
	self:update_count()
end

local function add_notification(n, self)
	local notifs_layout = self.main_widget:get_children_by_id("notifs_layout")[1]
	if #notifs_layout.children == 1 and self.is_empty then
		notifs_layout:reset()
		self.is_empty = false
	end
	local new_notification_widget = create_notification_widget(n)
	notifs_layout:insert(1, new_notification_widget)
	n:connect_signal("destroyed", function()
		remove_notification(new_notification_widget, self)
	end)
	self:update_count()
end

function notification_list:clear_notifications()
	local notifs_layout = self.main_widget:get_children_by_id("notifs_layout")[1]
	notifs_layout:reset()
	notifs_layout:insert(1, self.empty_massage)
	self.is_empty = true
	self:update_count()
	naughty.destroy_all_notifications(nil, naughty.notification_closed_reason.silent)
end

function notification_list:update_count()
	local notifs_layout = self.main_widget:get_children_by_id("notifs_layout")[1]
	local count = self.main_widget:get_children_by_id("count")[1]
	if not self.is_empty then
		count:set_markup("(" .. #notifs_layout.children .. ")")
	else
		count:set_markup("")
	end
end

local function new()
	local ret = {}
	gtable.crush(ret, notification_list, true)

	local dnd_button
	dnd_button = widgets.hover_button {
		markup = text_icons.bell_on,
		bg_normal = beautiful.bg,
		margins = { right = dpi(11), left = dpi(11) },
		buttons = {
			awful.button({}, 1, function()
				notifications:toggle_silent()
				if notifications.silent then
					dnd_button:set_text(text_icons.bell_off)
				else
					dnd_button:set_text(text_icons.bell_on)
				end
			end)
		}
	}

	local clear_button = widgets.hover_button {
		markup = text_icons.trash,
		fg_normal = beautiful.red,
		bg_normal = beautiful.bg,
		bg_hover = beautiful.red,
		margins = { right = dpi(11), left = dpi(11) },
		buttons = {
			awful.button({}, 1, function()
				ret:clear_notifications()
			end)
		}
	}

	ret.empty_massage = wibox.widget {
		widget = wibox.container.background,
		fg = beautiful.fg_alt,
		forced_height = dpi(560),
		{
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h2,
			markup = "No notifications"
		}
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(50) + dpi(560),
		forced_width = dpi(450),
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(6),
			{
				widget = wibox.container.background,
				forced_height = dpi(40),
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.margin,
						margins = { left = dpi(7) },
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(10),
							{
								widget = wibox.widget.textbox,
								align = "center",
								markup = "Notifications"
							},
							{
								id = "count",
								widget = wibox.widget.textbox
							}
						}
					},
					nil,
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = beautiful.sep_width,
						spacing_widget = widgets.separator {
							margins = { top = dpi(8), bottom = dpi(8) }
						},
						dnd_button,
						clear_button
					}
				}
			},
			{
				id = "notifs_layout",
				layout = wibox.layout.overflow.vertical,
				scrollbar_enabled = false,
				step = 80,
				spacing = dpi(6)
			}
		}
	}

	local notifs_layout = ret.main_widget:get_children_by_id("notifs_layout")[1]
	ret.is_empty = true
	notifs_layout:insert(1, ret.empty_massage)

	naughty.connect_signal("request::display", function(n)
		add_notification(n, ret)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
