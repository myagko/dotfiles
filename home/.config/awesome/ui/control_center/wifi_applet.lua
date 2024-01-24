local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local wifi_daemon = require("daemons.wifi")

local Wifi_applet = {}

local function create_hover_button(widget)
	local box = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		fg = beautiful.foreground,
		forced_width = 55,
		widget
	}
	box:connect_signal("mouse::enter", function()
		box.bg = beautiful.accent
		box.fg = beautiful.background
	end)
	box:connect_signal("mouse::leave", function()
		box.bg = beautiful.background_alt
		box.fg = beautiful.foreground
	end)
	return box
end

Wifi_applet.m_button_revealer = wibox.widget {
	widget = wibox.widget.textbox,
	text = ""
}

Wifi_applet.m_button_label = wibox.widget {
	widget = wibox.widget.textbox,
}

Wifi_applet.m_button = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	fg = beautiful.foreground,
	forced_height = 55,
	{
		widget = wibox.container.margin,
		margins = { left = 15, right = 15 },
		{
			layout = wibox.layout.align.horizontal,
			Wifi_applet.m_button_label,
			nil,
			Wifi_applet.m_button_revealer
		}
	}
}

Wifi_applet.b_close_button = create_hover_button(wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	font = helpers:inc_fontsize(1.5),
	text = ""
})

Wifi_applet.b_refresh_button = create_hover_button(wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	font = helpers:inc_fontsize(1.5),
	text = ""
})

Wifi_applet.b_toggle_button = create_hover_button(wibox.widget {
	widget = wibox.widget.textbox,
	align = "center",
	font = helpers:inc_fontsize(4.5),
})

Wifi_applet.massage = wibox.widget {
	widget = wibox.container.background,
	fg = beautiful.foreground_alt,
	forced_height = 9*50,
	{
		widget = wibox.widget.textbox,
		align = "center",
		font = helpers:inc_fontsize(5),
	}
}

Wifi_applet.passbox_prompt = wibox.widget {
	widget = wibox.widget.textbox
}

Wifi_applet.passbox_title = wibox.widget {
	widget = wibox.widget.textbox,
}

Wifi_applet.passbox = wibox.widget {
	widget = wibox.container.background,
	forced_height = 9*50,
	{
		layout = wibox.layout.fixed.vertical,
		spacing = 20,
		{
			widget = wibox.container.margin,
			margins = 10,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 20,
				{
					widget = wibox.container.background,
					buttons = {
						awful.button({}, 1, function()
							Wifi_applet:close_passbox()
						end)
					},
					{
						widget = wibox.widget.textbox,
						text = ""
					}
				},
				Wifi_applet.passbox_title
			}
		},
		{
			widget = wibox.container.background,
			bg = beautiful.background_alt,
			fg = beautiful.foreground_alt,
			{
				widget = wibox.container.margin,
				margins = 10,
				{
					layout = wibox.layout.fixed.vertical,
					spacing = 10,
					{
						widget = wibox.widget.textbox,
						text = "Password: "
					},
					{
						widget = wibox.container.background,
						fg = beautiful.foreground,
						Wifi_applet.passbox_prompt
					}
				}
			}
		}
	}
}

Wifi_applet.active_ap_container = wibox.widget {
	layout = wibox.layout.fixed.vertical
}

Wifi_applet.ap_container = wibox.widget {
	layout = wibox.layout.overflow.vertical,
	scrollbar_enabled = false,
	step = 80,
}

Wifi_applet.bottombar = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	forced_height = 55,
	{
		layout = wibox.layout.align.horizontal,
		Wifi_applet.b_toggle_button,
		nil,
		{
			layout = wibox.layout.fixed.horizontal,
			Wifi_applet.b_refresh_button,
			Wifi_applet.b_close_button
		},
	}
}

Wifi_applet.m_layout_sep = wibox.widget {
	widget = wibox.container.background,
	forced_height = beautiful.sep_width,
	bg = beautiful.border_color
}

Wifi_applet.m_layout = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = 15
}

Wifi_applet.main_widget = wibox.widget {
	widget = wibox.container.background,
	{
		layout = wibox.layout.fixed.vertical,
		spacing = 20,
		{
			widget = wibox.container.background,
			forced_height = 9*50,
			Wifi_applet.m_layout
		},
		Wifi_applet.bottombar
	}
}

function Wifi_applet:add_entries(list)
	self.ap_container:reset()
	self.active_ap_container:reset()
	self.m_layout:reset()
	self.m_layout:add(self.active_ap_container, self.ap_container)
	for _, entry in ipairs(list) do
		local entry_info = wibox.widget {
			widget = wibox.widget.textbox
		}
		local wifi_entry = wibox.widget {
			widget = wibox.container.background,
			forced_height = 50,
			{
				widget = wibox.container.margin,
				margins = 10,
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.widget.textbox,
						text = entry.ssid
					},
					nil,
					entry_info
				}
			}
		}

		if entry.active == "yes" then
			entry_info.text = ""
			self.active_ap_container:add(wifi_entry, Wifi_applet.m_layout_sep)
			self.m_button_label.text = " " .. entry.ssid
		elseif entry.active:match("no") then
			if entry.security:match("WPA") then
				entry_info.text = ""
			else
				entry_info.text = ""
			end
			wifi_entry.buttons = {
				awful.button({}, 1, function()
					self:enter_passwd(entry.ssid, entry.bssid, entry.security)
				end)
			}
			self.ap_container:add(wifi_entry)
		end
	end
end

function Wifi_applet:enter_passwd(ssid, bssid, security)
	self.passbox.state = true
	self.m_layout:reset()
	self.m_layout:add(self.passbox)
	self.passbox_title.text = ssid
	awful.prompt.run {
		textbox = self.passbox_prompt,
		bg_cursor = beautiful.foreground,
		done_callback = function()
			self.m_layout:reset()
			self.m_layout:add(self.active_ap_container, self.ap_container)
		end,
		exe_callback = function(input)
			wifi_daemon:connect(ssid, bssid, security, input)
			self:refresh()
		end
	}
end

function Wifi_applet:close_passbox()
	self.passbox.state = false
	awful.keygrabber.stop()
	self.m_layout:reset()
	self.m_layout:add(self.active_ap_container, self.ap_container)
end

function Wifi_applet:refresh()
	self.ap_container:reset()
	self.active_ap_container:reset()
	wifi_daemon:get_status()
end

awesome.connect_signal("wifi:status", function(status)
	if status then
		Wifi_applet.b_toggle_button.widget.text = ""
		Wifi_applet.m_button_label.text = " Enabled"
		Wifi_applet.m_button.bg = beautiful.accent
		Wifi_applet.m_button.fg = beautiful.background
	else
		Wifi_applet.b_toggle_button.widget.text = ""
		Wifi_applet.massage.widget.text = "Wifi disabled"
		Wifi_applet.m_button_label.text = " Disabled"
		Wifi_applet.m_button.bg = beautiful.background_alt
		Wifi_applet.m_button.fg = beautiful.foreground
		Wifi_applet.m_layout:reset()
		Wifi_applet.m_layout:add(Wifi_applet.massage)
	end
end)

awesome.connect_signal("wifi:scan_started", function()
	Wifi_applet.m_layout:reset()
	Wifi_applet.m_layout:add(Wifi_applet.massage)
	Wifi_applet.massage.widget.text = " Please wait"
end)

awesome.connect_signal("wifi:scan_finished", function(wifi_list)
	Wifi_applet:add_entries(wifi_list)
end)

Wifi_applet.b_toggle_button:buttons {
	awful.button({}, 1, function()
		wifi_daemon:toggle()
	end)
}

Wifi_applet.m_button_label:buttons {
	awful.button({}, 1, function()
		wifi_daemon:toggle()
	end)
}

Wifi_applet.b_refresh_button:buttons {
	awful.button({}, 1, function()
		Wifi_applet:refresh()
	end)
}

return Wifi_applet
