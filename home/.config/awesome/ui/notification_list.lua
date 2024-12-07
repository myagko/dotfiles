local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local widgets = require("widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local notifications = require("ui.notifications")

local notification_list = {}
local instance = nil

local function create_notif(n)
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

	local ntime = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(os.date("%H:%M"), { fg = beautiful.foreground_alt })
	}

	local nicon = wibox.widget {
		widget = wibox.widget.imagebox,
		resize = true,
		halign = "center",
		valign = "top",
		image = n.icon
	}

	local nclose = wibox.widget {
		widget = wibox.widget.textbox,
		markup = text_icons.cross
	}

	local nexpand = wibox.widget {
		widget = wibox.widget.textbox,
		markup = text_icons.arrow_down
	}

	local nwidget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		forced_height = dpi(130),
		{
			widget = wibox.container.margin,
			margins = dpi(20),
			{
				layout = wibox.layout.fixed.horizontal,
				fill_space = true,
				spacing = dpi(20),
				{
					widget = wibox.container.constraint,
					height = dpi(85),
					width = dpi(85),
					strategy = "max",
					nicon
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = dpi(5),
					{
						layout = wibox.layout.align.horizontal,
						{
							widget = wibox.container.constraint,
							width = dpi(150),
							{
								widget = wibox.container.scroll.horizontal,
								step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
								speed = 50,
								ntitle
							}
						},
						nil,
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(10),
							ntime,
							nexpand,
							nclose
						}
					},
					widgets.separator {
						dir = "h",
						size = beautiful.sep_width
					},
					nmassage
				}
			}
		}
	}

	local is_expanded = false

	nexpand:buttons {
		awful.button({}, 1, function()
			is_expanded = not is_expanded
			if is_expanded then
				nwidget.forced_height = dpi(210)
				nexpand.markup = text_icons.arrow_up
			else
				nwidget.forced_height = dpi(130)
				nexpand.markup = text_icons.arrow_down
			end
		end)
	}

	nclose:buttons {
		awful.button({}, 1, function()
			notification_list:remove_notif(nwidget)
		end)
	}

	return nwidget
end

function notification_list:update_count()
	if not self.is_empty then
		self.count_msg.markup = "(" .. #self.m_layout.children .. ")"
	else
		self.count_msg.markup = ""
	end
end

function notification_list:reset_notifs()
	self.m_layout:reset()
	self.m_layout:insert(1, self.empty_massage)
	self.is_empty = true
	self:update_count()
end

function notification_list:remove_notif(w)
	self.m_layout:remove_widgets(w)

	if #self.m_layout.children == 0 then
		self.m_layout:insert(1, self.empty_massage)
		self.is_empty = true
	end

	self:update_count()
end

function notification_list:add_notifs(n)
	if #self.m_layout.children == 1 and self.is_empty then
		self.m_layout:reset()
		self.is_empty = false
	end

	if beautiful.notif_list_limit and #self.m_layout.children >= beautiful.notif_list_limit then
		self:remove_notif(self.m_layout.children[beautiful.notif_list_limit])
	end

	self.m_layout:insert(1, create_notif(n))
	self:update_count()
end

local function new()
	local ret = notification_list

	ret.dnd_button = widgets.hover_button {
		markup = text_icons.bell_on,
		bg_normal = beautiful.background,
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
		bg_normal = beautiful.background,
		bg_hover = beautiful.red,
		margins = { right = dpi(16), left = dpi(16) },
		buttons = {
			awful.button({}, 1, function()
				ret:reset_notifs()
			end)
		}
	}

	ret.count_msg = wibox.widget {
		widget = wibox.widget.textbox
	}

	ret.empty_massage = wibox.widget {
		widget = wibox.container.background,
		fg = beautiful.foreground_alt,
		forced_height = dpi(560),
		{
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h2,
			markup = "No notifications"
		}
	}

	ret.m_layout = wibox.widget {
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
			ret.m_layout
		}
	}

	ret.is_empty = true
	ret.m_layout:insert(1, ret.empty_massage)

	naughty.connect_signal("request::display", function(n)
		ret:add_notifs(n)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
