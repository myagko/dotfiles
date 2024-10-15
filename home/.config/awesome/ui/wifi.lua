local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local network_daemon = require("daemons.network")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local wifi_applet = {}
local instance = nil

function wifi_applet:crate_ap_widget(access_point)
	local name = wibox.widget {
		widget = wibox.widget.textbox,
		markup = access_point:is_active() and access_point.ssid .. " - Activated" or access_point.ssid,
	}

	local strenght = wibox.widget {
		widget = wibox.widget.textbox,
		markup = access_point.strength > 70 and "▂▄▆█"
			or access_point.strength > 45 and "▂▄▆"
			or access_point.strength > 20 and "▂▄"
			or "▂"
	}

	local ap_widget = wibox.widget {
		active = access_point:is_active(),
		widget = wibox.container.background,
		{
			widget = wibox.container.margin,
			forced_height = dpi(50),
			margins = dpi(10),
			buttons = {
				awful.button({}, 1, function()
					self:open_ap_menu(access_point)
				end)
			},
			{
				layout = wibox.layout.align.horizontal,
				{
					widget = wibox.container.constraint,
					width = dpi(250),
					name
				},
				nil,
				strenght
			}
		}
	}

	ap_widget:connect_signal("mouse::enter", function(w)
		w.bg = beautiful.background_urgent
	end)

	ap_widget:connect_signal("mouse::leave", function(w)
		w.bg = beautiful.background
	end)

	table.insert(self.ap_widgets, ap_widget)

	return ap_widget
end

function wifi_applet:open_ap_menu(access_point)
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

	title.markup = access_point.ssid

	close:buttons {
		awful.button({}, 1, function()
			self:close_ap_menu()
		end)
	}

	obscure_button.markup = text_icons.invisible
	obscure_button:buttons {
		awful.button({}, 1, function()
			obscure = not obscure
			if obscure then
				obscure_button.markup = text_icons.invisible
			else
				obscure_button.markup = text_icons.visible
			end
		end)
	}

	auto_connect_button.markup = text_icons.check_on
	auto_connect_button:buttons {
		awful.button({}, 1, function()
			auto_connect = not auto_connect
			if auto_connect then
				auto_connect_button.markup = text_icons.check_on
			else
				auto_connect_button.markup = text_icons.check_off
			end
		end)
	}

	if access_point:is_active() then
		connect_or_disconnect.widget = self.disconnect_widget
	else
		local pass_input = ""
		connect_or_disconnect.widget = self.connect_widget

		awful.prompt.run {
			textbox = pass_prompt,
			bg_cursor = beautiful.foreground,
			fg_cursor = beautiful.foreground,
			done_callback = function()
				self:close_ap_menu()
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

		self.connect_button:buttons {
			awful.button({}, 1, function()
				access_point:connect(pass_input, auto_connect)
				self:close_ap_menu()
			end)
		}
	end
end

function wifi_applet:close_ap_menu()
	if network_daemon._private.client_proxy.WirelessEnabled then
		awful.keygrabber.stop()
		self.main_layout:reset()
		for _, ap_widget in ipairs(self.ap_widgets) do
			if ap_widget.active then
				self.main_layout:insert(1, ap_widget)
			else
				self.main_layout:add(ap_widget)
			end
		end
	end
end

function wifi_applet:refresh()
	self.ap_widgets = {}
	network_daemon:scan_access_points()
end

function wifi_applet:on_scan_success(access_points)
	self.ap_widgets = {}
	self.main_layout:reset()

	for _, access_point in pairs(access_points) do
		if access_point:is_active() then
			self.main_layout:insert(1, self:crate_ap_widget(access_point))
		else
			self.main_layout:add(self:crate_ap_widget(access_point))
		end
	end
end

function wifi_applet:on_wireless_state_changed(state)
	self.ap_widgets = {}
	if state then
		self.bottombar_toggle_button:set_text(text_icons.switch_on)
		self.control_button.bg = beautiful.accent
		self.control_button.fg = beautiful.background
		self.control_button_sep:set_color(beautiful.background)
		self.control_button_label.markup = "Enabled"
		self.main_layout:reset()
		self.main_layout:add(self.massage_widget)
		self.massage_widget:set_text(text_icons.wait)
	else
		self.bottombar_toggle_button:set_text(text_icons.switch_off)
		self.control_button.bg = beautiful.background_alt
		self.control_button.fg = beautiful.foreground
		self.control_button_sep:set_color(beautiful.background_urgent)
		self.control_button_label.markup = "Disabled"
		self.main_layout:reset()
		self.main_layout:add(self.massage_widget)
		self.massage_widget:set_text("Wifi Disabled")
	end
end

local function new()
	local ret = wifi_applet

	ret.ap_widgets = {}

	ret.control_button_sep = helpers.ui.create_sep {
		orientation = "v",
		margins = { top = dpi(10), bottom = dpi(10) }
	}

	ret.control_button_label = wibox.widget {
		widget = wibox.widget.textbox
	}

	ret.control_button_revealer = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(45),
		{
			widget = wibox.widget.textbox,
			align = "center",
			markup = text_icons.arrow_right
		}
	}

	ret.control_button = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		fg = beautiful.foreground,
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
							markup = text_icons.wifi
						},
						ret.control_button_label
					}
				},
				nil,
				{
					layout = wibox.layout.fixed.horizontal,
					ret.control_button_sep,
					ret.control_button_revealer
				}
			}
		}
	}

	ret.control_button:connect_signal("mouse::enter", function(w)
		if not network_daemon._private.client_proxy.WirelessEnabled then
			w.bg = beautiful.background_urgent
			ret.control_button_sep:set_color(beautiful.foreground_alt)
		end
	end)

	ret.control_button:connect_signal("mouse::leave", function(w)
		if not network_daemon._private.client_proxy.WirelessEnabled then
			w.bg = beautiful.background_alt
			ret.control_button_sep:set_color(beautiful.background_urgent)
		end
	end)

	ret.bottombar_close_button = helpers.ui.create_hover_button {
		markup = text_icons.arrow_left,
		forced_width = dpi(55),
		forced_height = dpi(55),
	}

	ret.bottombar_refresh_button = helpers.ui.create_hover_button {
		markup = text_icons.reboot,
		forced_width = dpi(55),
		forced_height = dpi(55),
		buttons = {
			awful.button({}, 1, function()
				ret:refresh()
			end)
		}
	}

	ret.bottombar_toggle_button = helpers.ui.create_hover_button {
		forced_width = dpi(55),
		forced_height = dpi(55),
		buttons = {
			awful.button({}, 1, function()
				network_daemon:toggle_wireless_state()
			end)
		}
	}

	ret.bottombar = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		forced_height = dpi(55),
		{
			layout = wibox.layout.align.horizontal,
			ret.bottombar_toggle_button,
			nil,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = beautiful.sep_width,
				spacing_widget = helpers.ui.create_sep {
					orientation = "v",
					margins = { top = dpi(10), bottom = dpi(10) }
				},
				ret.bottombar_refresh_button,
				ret.bottombar_close_button
			}
		}
	}

	ret.massage_widget = wibox.widget {
		widget = wibox.container.background,
		fg = beautiful.foreground_alt,
		forced_height = dpi(400),
		{
			id = "massage_text",
			widget = wibox.widget.textbox,
			align = "center",
			font = beautiful.font_h2
		},
		set_text = function(w, markup)
			w:get_children_by_id("massage_text")[1].markup = markup
		end
	}

	ret.connect_button = helpers.ui.create_hover_button {
		markup = "Connect",
		margins = dpi(10)
	}

	ret.connect_widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(15),
		{
			widget = wibox.container.background,
			bg = beautiful.background_alt,
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
								markup = "Auto connect"
							},
							nil,
							{
								id = "auto_connect_checkbox",
								widget = wibox.widget.textbox,
								markup = text_icons.selected
							}
						}
					}
				}
			}
		},
		ret.connect_button
	}

	ret.disconnect_button = helpers.ui.create_hover_button {
		markup = "Disonnect",
		margins = dpi(10),
		buttons = {
			awful.button({}, 1, function()
				network_daemon:disconnect_from_active_access_point()
				network_daemon:scan_access_points()
			end)
		}
	}

	ret.disconnect_widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		ret.disconnect_button
	}

	ret.ap_menu = wibox.widget {
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
						markup = text_icons.arrow_left
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

	ret.main_layout = wibox.widget {
		layout = wibox.layout.overflow.vertical,
		scrollbar_enabled = false,
		step = 40
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(20),
			{
				widget = wibox.container.background,
				forced_height = dpi(400),
				forced_width = dpi(400),
				ret.main_layout
			},
			ret.bottombar
		}
	}

	network_daemon:connect_signal("scan_access_points::success", function(_, access_points)
		ret:on_scan_success(access_points)
	end)

	network_daemon:connect_signal("wireless_state", function(_, state)
		ret:on_wireless_state_changed(state)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
