local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local helpers = require("helpers")

local Notifs_list = {}

Notifs_list.label = wibox.widget {
	markup = "Notifications",
	valign = "center",
	widget = wibox.widget.textbox,
}

Notifs_list.count_t = wibox.widget {
	valign = "center",
	widget = wibox.widget.textbox,
}

Notifs_list.clear_button = wibox.widget {
	markup = helpers:colorize_markup("", beautiful.red),
	valign = "center",
	widget = wibox.widget.textbox,
}

Notifs_list.empty_massage = wibox.widget {
	forced_height = beautiful.notif_list_height,
	widget = wibox.container.background,
	fg = beautiful.foreground_alt,
	{
		text = "No notifications",
		font = helpers:inc_fontsize(5),
		align = "center",
		widget = wibox.widget.textbox,
	},
}

Notifs_list.m_layout = wibox.widget {
	layout = wibox.layout.overflow.vertical,
	scrollbar_enabled = false,
	step = 80,
	spacing = 10,
}

Notifs_list.main_widget = wibox.widget {
	widget = wibox.container.background,
	forced_height = beautiful.notif_list_header_height + beautiful.notif_list_height,
	forced_width = beautiful.notif_list_width,
	{
		layout = wibox.layout.fixed.vertical,
		spacing = 20,
		{
			widget = wibox.container.margin,
			margins = { left = 20, right = 20 },
			{
				widget = wibox.container.background,
				forced_height = beautiful.notif_list_header_height,
				{
					layout = wibox.layout.align.horizontal,
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = 10,
						Notifs_list.label,
						Notifs_list.count_t
					},
					nil,
					Notifs_list.clear_button
				}
			}
		},
		Notifs_list.m_layout,
	}
}

Notifs_list.is_empty = true

function Notifs_list:reset_notifs()
	self.m_layout:reset()
	self.m_layout:insert(1, self.empty_massage)
	self.is_empty = true
end

Notifs_list.clear_button:buttons {
	awful.button({}, 1, function()
		Notifs_list.count_t.text = ""
		Notifs_list:reset_notifs()
	end)
}

function Notifs_list:remove_notif(index)
	self.m_layout:remove_widgets(index)

	if #self.m_layout.children == 0 then
		self.m_layout:insert(1, self.empty_massage)
		self.is_empty = true
	end
end

function Notifs_list:create_notif(icon, n)

	local nsep = wibox.widget {
		widget = wibox.widget.background,
		bg = beautiful.background_urgent,
		forced_height = beautiful.sep_width
	}

	local nmassage = wibox.widget {
		widget = wibox.widget.textbox,
		font = helpers:inc_fontsize(-1.5),
		text = n.massage or n.text
	}

	local ntitle = wibox.widget {
		widget = wibox.widget.textbox,
		text = n.title
	}

	local ntime = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers:colorize_markup(os.date("%H:%M:%S"), beautiful.foreground_alt)
	}

	local nicon = wibox.widget {
		widget = wibox.widget.imagebox,
		resize = true,
		halign = "center",
		valign = "top",
		image = icon
	}

	local nwidget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		forced_height = beautiful.notif_list_item_height,
		{
			widget = wibox.container.margin,
			margins = 20,
			{
				layout = wibox.layout.fixed.horizontal,
				fill_space = true,
				spacing = 20,
				{
					widget = wibox.container.constraint,
					height = 80,
					width = 80,
					strategy = "max",
					nicon
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = 5,
					{
						layout = wibox.layout.align.horizontal,
						{
							widget = wibox.container.background,
							{
								widget = wibox.container.scroll.horizontal,
								step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
								speed = 50,
								ntitle
							}
						},
						nil,
						ntime
					},
					nsep,
					nmassage
				}
			}
		}
	}

	if n.urgency == "critical" then
		nwidget.fg = beautiful.red
	end

	nwidget.buttons = {
		awful.button({}, 3, function()
			self:remove_notif(nwidget)
			if self.is_empty then
				self.count_t.text = ""
			else
				self.count_t.text = "(" .. #self.m_layout.children .. ")"
			end
		end)
	}

	return nwidget
end

Notifs_list.m_layout:insert(1, Notifs_list.empty_massage)

naughty.connect_signal("request::display", function(n)
	if #Notifs_list.m_layout.children == 1 and Notifs_list.is_empty then
		Notifs_list.m_layout:reset()
		Notifs_list.is_empty = false
	end

	local appicon = n.icon or n.app_icon
	if not appicon then
		appicon = beautiful.icon_bell
	end

	Notifs_list.m_layout:insert(1, Notifs_list:create_notif(appicon, n))
	Notifs_list.count_t.text = "(" .. #Notifs_list.m_layout.children .. ")"
end)

return Notifs_list.main_widget
