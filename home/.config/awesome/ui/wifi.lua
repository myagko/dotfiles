local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local network_daemon = require("daemons.network")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local applet = {}

applet.control_button = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	fg = beautiful.foreground,
	border_width = beautiful.comp_border_width,
	border_color = beautiful.border_color,
	forced_height = dpi(55),
	{
		widget = wibox.container.margin,
		margins = { left = dpi(15) },
		{
			layout = wibox.layout.align.horizontal,
			{
				widget = wibox.container.background,
				forced_width = dpi(150),
				buttons = {
					awful.button({}, 1, function()
						network_daemon:toggle_wireless_state()
					end)
				},
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(10),
					{
						widget = wibox.widget.textbox,
						text = text_icons.wifi_on
					},
					{
						id = "label",
						widget = wibox.widget.textbox
					}
				}
			},
			nil,
			{
				layout = wibox.layout.fixed.horizontal,
				helpers.ui.create_sep {
					orientation = "v",
					margins = { top = dpi(10), bottom = dpi(10) }
				},
				{
					id = "revealer",
					widget = wibox.container.background,
					forced_width = dpi(45),
					{
						widget = wibox.widget.textbox,
						align = "center",
						text = text_icons.arrow_right
					}
				}
			}
		}
	},
	get_label = function(widget)
		return widget:get_children_by_id("label")[1]
	end,
	get_revealer = function(widget)
		return widget:get_children_by_id("revealer")[1]
	end
}

applet.bottombar_close_button = helpers.ui.create_hover_button {
	text = text_icons.arrow_left,
	forced_width = dpi(55),
	forced_height = dpi(55),
}

applet.bottombar_refresh_button = helpers.ui.create_hover_button {
	text = text_icons.reboot,
	forced_width = dpi(55),
	forced_height = dpi(55),
	buttons = {
		awful.button({}, 1, function()
			network_daemon:scan_access_points()
		end)
	}
}

applet.bottombar_toggle_button = helpers.ui.create_hover_button {
	forced_width = dpi(55),
	forced_height = dpi(55),
	font = helpers.ui.font(beautiful.font_size + dpi(5)),
	buttons = {
		awful.button({}, 1, function()
			network_daemon:toggle_wireless_state()
		end)
	}
}

applet.bottombar = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	border_width = beautiful.comp_border_width,
	border_color = beautiful.border_color,
	forced_height = dpi(55),
	{
		layout = wibox.layout.align.horizontal,
		applet.bottombar_toggle_button,
		nil,
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = beautiful.sep_width,
			spacing_widget = helpers.ui.create_sep {
				orientation = "v",
				margins = { top = 6, bottom = 6 }
			},
			applet.bottombar_refresh_button,
			applet.bottombar_close_button
		}
	}
}

applet.massage_widget = wibox.widget {
	widget = wibox.container.background,
	fg = beautiful.foreground_alt,
	forced_height = dpi(400),
	{
		id = "massage_text",
		widget = wibox.widget.textbox,
		align = "center",
		font = helpers.ui.font(beautiful.font_size + dpi(5))
	},
	set_text = function(widget, text)
		widget:get_children_by_id("massage_text")[1].text = text
	end
}

applet.connect_button = helpers.ui.create_hover_button {
	text = "Connect",
	border_width = beautiful.comp_border_width,
	border_color = beautiful.border_color,
	margins = dpi(10)
}

applet.connect_widget = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = dpi(15),
	{
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		{
			widget = wibox.container.margin,
			margins = dpi(15),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(10),
				{
					widget = wibox.container.margin,
					margins = { left = dpi(10), right = dpi(10) },
					{
						layout = wibox.layout.align.horizontal,
						{
							widget = wibox.container.background,
							forced_width = dpi(310),
							{
								id = "pass_prompt",
								widget = wibox.widget.textbox
							}
						},
						nil,
						{
							id = "obscure",
							widget = wibox.widget.textbox,
						}
					}
				},
				helpers.ui.create_sep {
					orientation = "h",
				},
				{
					widget = wibox.container.margin,
					margins = { left = dpi(10), right = dpi(10) },
					{
						layout = wibox.layout.align.horizontal,
						{
							widget = wibox.widget.textbox,
							text = "Auto connect"
						},
						nil,
						{
							id = "auto_connect_checkbox",
							widget = wibox.widget.textbox,
							text = text_icons.selected
						}
					}
				}
			}
		}
	},
	applet.connect_button
}

applet.disconnect_button = helpers.ui.create_hover_button {
	text = "Disonnect",
	border_width = beautiful.comp_border_width,
	border_color = beautiful.border_color,
	margins = dpi(10),
	buttons = {
		awful.button({}, 1, function()
			network_daemon:disconnect_from_active_access_point()
			network_daemon:scan_access_points()
		end)
	}
}

applet.disconnect_widget = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	applet.disconnect_button
}

applet.ap_menu = wibox.widget {
	widget = wibox.container.background,
	forced_height = dpi(400),
	{
		layout = wibox.layout.fixed.vertical,
		{
			widget = wibox.container.margin,
			margins = dpi(15),
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(15),
				{
					id = "close",
					widget = wibox.widget.textbox,
					text = text_icons.arrow_left
				},
				{
					id = "title",
					widget = wibox.widget.textbox
				}
			}
		},
		{
			id = "connect_or_disconnect",
			widget = wibox.container.background
		}
	}
}

applet.main_layout = wibox.widget {
	layout = wibox.layout.overflow.vertical,
	spacing = dpi(15),
	scrollbar_enabled = false,
	step = 40
}

applet.main_widget = wibox.widget {
	widget = wibox.container.background,
	{
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(20),
		{
			widget = wibox.container.background,
			forced_height = dpi(400),
			forced_width = dpi(400),
			applet.main_layout
		},
		applet.bottombar
	}
}

function applet:crate_ap_widget(access_point)
	local name = wibox.widget {
		widget = wibox.widget.textbox,
		text = access_point:is_active() and access_point.ssid .. " - Activated" or access_point.ssid,
	}

	local strenght = wibox.widget {
		widget = wibox.widget.textbox,
		text = access_point.strength > 70 and "▂▄▆█"
			or access_point.strength > 45 and "▂▄▆ "
			or access_point.strength > 20 and "▂▄  "
			or "▂   "
	}

	local inst = wibox.widget {
		widget = wibox.container.margin,
		forced_height = dpi(40),
		margins = dpi(5),
		buttons = {
			awful.button({}, 1, function()
				self:open_ap_menu(access_point)
			end)
		},
		{
			layout = wibox.layout.align.horizontal,
			name,
			nil,
			strenght
		}
	}

	return inst
end

function applet:open_ap_menu(access_point)
	local obscure = true
	local auto_connect = true

	local close = self.ap_menu:get_children_by_id("close")[1]
	local title = self.ap_menu:get_children_by_id("title")[1]
	local connect_or_disconnect = self.ap_menu:get_children_by_id("connect_or_disconnect")[1]
	local pass_prompt = self.connect_widget:get_children_by_id("pass_prompt")[1]
	local obscure_button = self.connect_widget:get_children_by_id("obscure")[1]
	local auto_connect_button = self.connect_widget:get_children_by_id("auto_connect_checkbox")[1]

	self.main_layout:reset()
	self.main_layout:add(self.ap_menu)

	title.text = access_point.ssid

	close:buttons {
		awful.button({}, 1, function()
			self:close_ap_menu()
		end)
	}

	obscure_button.text = text_icons.invisible
	obscure_button:buttons {
		awful.button({}, 1, function()
			obscure = not obscure
			if obscure then
				obscure_button.text = text_icons.invisible
			else
				obscure_button.text = text_icons.visible
			end
		end)
	}

	auto_connect_button.text = text_icons.check_on
	auto_connect_button:buttons {
		awful.button({}, 1, function()
			auto_connect = not auto_connect
			if auto_connect then
				auto_connect_button.text = text_icons.check_on
			else
				auto_connect_button.text = text_icons.check_off
			end
		end)
	}

	if access_point:is_active() then
		connect_or_disconnect.widget = self.disconnect_widget
	else
		local pass_input = ""
		connect_or_disconnect.widget = self.connect_widget

		self.is_prompt_running = true
		awful.prompt.run {
			textbox = pass_prompt,
			bg_cursor = beautiful.foreground,
			fg_cursor = beautiful.foreground,
			done_callback = function()
				network_daemon:scan_access_points()
			end,
			exe_callback = function(input)
				pass_input = input
				access_point:connect(pass_input, auto_connect)
			end,
			highlighter = function(a, b)
				if not obscure then
					return a, b
				else
					local line = a .. "XXXCURSORXXX" .. b
					local b4curs1, b4curs2 = line:find("(.*)XXXCURSORXXX")
					local x, y = line:sub(b4curs1, b4curs2 - 12), line:sub(b4curs2 + 1, #line)
					return x:gsub("(.)", "*"), y:gsub("(.)", "*")
				end
			end
		}

		applet.connect_button:buttons {
			awful.button({}, 1, function()
				access_point:connect(pass_input, auto_connect)
				self:close_ap_menu()
			end)
		}
	end
end

function applet:close_ap_menu()
	if self.is_prompt_running then
		awful.keygrabber.stop()
	end

	network_daemon:scan_access_points()
end

function applet:on_scan_success(access_points)
	self.main_layout:reset()

	for _, access_point in pairs(access_points) do
		if access_point:is_active() then
			self.main_layout:insert(1, self:crate_ap_widget(access_point))
		else
			self.main_layout:add(self:crate_ap_widget(access_point))
		end
	end
end

function applet:on_wireless_state_changed(state)
	if state then
		self.bottombar_toggle_button:set_text(text_icons.switch_on)
		self.control_button:get_label().text = "Enabled"
		self.control_button.bg = beautiful.accent
		self.control_button.fg = beautiful.background
		self.main_layout:reset()
		self.main_layout:add(self.massage_widget)
		self.massage_widget:set_text(text_icons.wait)
	else
		self.bottombar_toggle_button:set_text(text_icons.switch_off)
		self.control_button:get_label().text = "Disabled"
		self.control_button.bg = beautiful.background_alt
		self.control_button.fg = beautiful.foreground
		self.main_layout:reset()
		self.main_layout:add(self.massage_widget)
		self.massage_widget:set_text("Wifi Disabled")
	end
end

network_daemon:connect_signal("scan_access_points::success", function(daemon, access_points)
	applet:on_scan_success(access_points)
end)

network_daemon:connect_signal("wireless_state", function(daemon, state)
	applet:on_wireless_state_changed(state)
end)

return applet
