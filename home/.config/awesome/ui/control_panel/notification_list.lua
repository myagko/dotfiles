local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local widgets = require("widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
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
		margins = { top = dpi(10) },
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
		markup = helpers.create_markup(n.app_name, {
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
		markup = helpers.create_markup(os.date("%H:%M"), { fg = beautiful.fg_alt })
	}

	local close = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(text_icons.cross, { fg = beautiful.red })
	}

	local n_widget = wibox.widget {
		widget = wibox.container.constraint,
		strategy = "max",
		height = 260,
		{
			widget = wibox.container.background,
			bg = beautiful.bg_alt,
			{
				widget = wibox.container.margin,
				margins = dpi(20),
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
					dir = "h",
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

	return n_widget
end

function notification_list:update_count()
	if not self.is_empty then
		self.count_msg.markup = "(" .. #self.main_layout.children .. ")"
	else
		self.count_msg.markup = ""
	end
end

function notification_list:clear_notifications()
	self.main_layout:reset()
	self.main_layout:insert(1, self.empty_massage)
	self.is_empty = true
	self:update_count()
	naughty.destroy_all_notifications(nil, naughty.notification_closed_reason.silent)
end

function notification_list:remove_notification(w)
	self.main_layout:remove_widgets(w)

	if #self.main_layout.children == 0 then
		self.main_layout:insert(1, self.empty_massage)
		self.is_empty = true
	end

	self:update_count()
end

function notification_list:add_notification(n)
	if #self.main_layout.children == 1 and self.is_empty then
		self.main_layout:reset()
		self.is_empty = false
	end

	local new_notification_widget = create_notification_widget(n)
	self.main_layout:insert(1, new_notification_widget)

	n:connect_signal("destroyed", function()
		self:remove_notification(new_notification_widget)
	end)

	self:update_count()
end

local function new()
	local ret = {}
	gtable.crush(ret, notification_list, true)

	ret.dnd_button = widgets.hover_button {
		markup = text_icons.bell_on,
		bg_normal = beautiful.bg,
		margins = { right = dpi(16), left = dpi(16) },
		buttons = {
			awful.button({}, 1, function()
				notifications:toggle_silent()
				if notifications.silent then
					ret.dnd_button:set_text(text_icons.bell_off)
				else
					ret.dnd_button:set_text(text_icons.bell_on)
				end
			end)
		}
	}

	ret.clear_button = widgets.hover_button {
		markup = text_icons.trash,
		fg_normal = beautiful.red,
		bg_normal = beautiful.bg,
		bg_hover = beautiful.red,
		margins = { right = dpi(16), left = dpi(16) },
		buttons = {
			awful.button({}, 1, function()
				ret:clear_notifications()
			end)
		}
	}

	ret.count_msg = wibox.widget {
		widget = wibox.widget.textbox
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

	ret.main_layout = wibox.widget {
		layout = wibox.layout.overflow.vertical,
		scrollbar_enabled = false,
		step = 80,
		spacing = dpi(10)
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(50) + dpi(560),
		forced_width = dpi(450),
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(10),
			{
				widget = wibox.container.background,
				forced_height = dpi(50),
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.margin,
						margins = 16,
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(10),
							{
								widget = wibox.widget.textbox,
								align = "center",
								markup = "Notifications"
							},
							ret.count_msg
						}
					},
					nil,
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = beautiful.sep_width,
						spacing_widget = widgets.separator {
							dir = "v",
							margins = { top = 6, bottom = 6 }
						},
						ret.dnd_button,
						ret.clear_button
					}
				}
			},
			ret.main_layout
		}
	}

	ret.is_empty = true
	ret.main_layout:insert(1, ret.empty_massage)

	naughty.connect_signal("request::display", function(n)
		ret:add_notification(n)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
