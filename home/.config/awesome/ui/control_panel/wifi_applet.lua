local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local widgets = require("widgets")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local network_daemon = require("daemons.network")

local wifi_applet = {}
local instance = nil

local function create_ap_widget(self, access_point)
	local name = wibox.widget {
		widget = wibox.widget.textbox,
		markup = access_point:is_active() and access_point.ssid .. " " .. text_icons.check
			or access_point.ssid
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
		w:set_bg(beautiful.bg_urg)
	end)

	ap_widget:connect_signal("mouse::leave", function(w)
		w:set_bg(beautiful.bg)
	end)

	return ap_widget
end

function wifi_applet:open_ap_menu(access_point)
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]
	local connect_widget_obscure = self.connect_widget:get_children_by_id("obscure")[1]
	local connect_widget_auto_connect = self.connect_widget:get_children_by_id("auto_connect")[1]
	local connect_widget_connect_button = self.connect_widget:get_children_by_id("connect_button")[1]
	local ap_menu_title = self.ap_menu:get_children_by_id("title")[1]
	local ap_menu_container = self.ap_menu:get_children_by_id("container")[1]

	local obscure = true
	local auto_connect = true

	aps_layout:reset()
	aps_layout:add(self.ap_menu)
	ap_menu_title:set_markup(access_point.ssid)

	connect_widget_obscure:set_markup(text_icons.eye_off)
	connect_widget_obscure:buttons { awful.button({}, 1, function()
		obscure = not obscure
		self.passwd_text_input:set_obscure(obscure)

		if obscure then
			connect_widget_obscure:set_markup(text_icons.eye_off)
		else
			connect_widget_obscure:set_markup(text_icons.eye_on)
		end
	end) }

	connect_widget_auto_connect:set_markup(text_icons.check_on)
	connect_widget_auto_connect:buttons { awful.button({}, 1, function()
		auto_connect = not auto_connect

		if auto_connect then
			connect_widget_auto_connect:set_markup(text_icons.check_on)
		else
			connect_widget_auto_connect:set_markup(text_icons.check_off)
		end
	end) }

	if access_point:is_active() then
		ap_menu_container:set_widget(self.disconnect_widget)
	else
		ap_menu_container:set_widget(self.connect_widget)
		self.passwd_text_input.exe_callback = function(input)
			access_point:connect(input, auto_connect)
		end
		connect_widget_connect_button:buttons { awful.button({}, 1, function()
			access_point:connect(self.passwd_text_input:get_input(), auto_connect)
			self:close_ap_menu()
		end) }
		self.passwd_text_input:run_keygrabber()
	end
end

function wifi_applet:close_ap_menu()
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]

	if network_daemon:get_wireless_state() then
		self.passwd_text_input:stop_keygrabber()
		self.passwd_text_input:set_obscure(true)
		aps_layout:reset()
		for _, ap_widget in ipairs(self.ap_widgets) do
			if ap_widget.active then
				aps_layout:insert(1, ap_widget)
			else
				aps_layout:add(ap_widget)
			end
		end
	end
end

function wifi_applet:refresh()
	self.ap_widgets = {}
	self.passwd_text_input:stop_keygrabber()
	network_daemon:scan_access_points()
end

function wifi_applet:on_scan_success(access_points)
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]
	self.ap_widgets = {}
	aps_layout:reset()

	for _, access_point in pairs(access_points) do
		local new_ap_widget = create_ap_widget(self, access_point)
		table.insert(self.ap_widgets, new_ap_widget)

		if access_point:is_active() then
			aps_layout:insert(1, new_ap_widget)
		else
			aps_layout:add(new_ap_widget)
		end
	end
end

function wifi_applet:on_wireless_state_changed(state)
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]
	local control_button_sep = self.control_button:get_children_by_id("separator")[1]
	local control_button_label = self.control_button:get_children_by_id("label")[1]
	local bottombar_toggle_button = self.bottombar:get_children_by_id("toggle_button")[1]
	self.ap_widgets = {}

	if state then
		bottombar_toggle_button:set_text(text_icons.switch_on)
		self.control_button:set_bg(beautiful.accent)
		self.control_button:set_fg(beautiful.bg)
		control_button_sep:set_color(beautiful.bg)
		control_button_label:set_markup("Enabled")
		aps_layout:reset()
		aps_layout:add(self.massage_widget)
		self.massage_widget:set_text(text_icons.wait)
	else
		bottombar_toggle_button:set_text(text_icons.switch_off)
		self.control_button:set_bg(beautiful.bg_alt)
		self.control_button:set_fg(beautiful.fg)
		control_button_sep:set_color(beautiful.bg_urg)
		control_button_label:set_markup("Disabled")
		aps_layout:reset()
		aps_layout:add(self.massage_widget)
		self.massage_widget:set_text("Wifi Disabled")
		self.passwd_text_input:stop_keygrabber()
	end
end

local function new()
	local ret = {}
	gtable.crush(ret, wifi_applet, true)
	ret.ap_widgets = {}

	ret.control_button = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		fg = beautiful.fg,
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
						{
							id = "label",
							widget = wibox.widget.textbox
						}
					}
				},
				nil,
				{
					layout = wibox.layout.fixed.horizontal,
					{
						id = "separator",
						widget = widgets.separator {
							margins = { top = dpi(10), bottom = dpi(10) }
						}
					},
					{
						id = "revealer",
						widget = wibox.container.background,
						forced_width = dpi(45),
						{
							widget = wibox.widget.textbox,
							align = "center",
							markup = text_icons.arrow_right
						}
					}
				}
			}
		}
	}

	ret.control_button:connect_signal("mouse::enter", function(w)
		if not network_daemon:get_wireless_state() then
			w:set_bg(beautiful.bg_urg)
			w:get_children_by_id("separator")[1]:set_color(beautiful.fg_alt)
		end
	end)

	ret.control_button:connect_signal("mouse::leave", function(w)
		if not network_daemon:get_wireless_state() then
			w:set_bg(beautiful.bg_alt)
			w:get_children_by_id("separator")[1]:set_color(beautiful.bg_urg)
		end
	end)

	ret.bottombar = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		forced_height = dpi(55),
		{
			layout = wibox.layout.align.horizontal,
			{
				id = "toggle_button",
				widget = widgets.hover_button {
					forced_width = dpi(55),
					forced_height = dpi(55),
					buttons = {
						awful.button({}, 1, function()
							network_daemon:toggle_wireless_state()
						end)
					}
				}
			},
			nil,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = beautiful.sep_width,
				spacing_widget = widgets.separator {
					margins = { top = dpi(10), bottom = dpi(10) }
				},
				{
					id = "refresh_button",
					widget = widgets.hover_button {
						markup = text_icons.reboot,
						forced_width = dpi(55),
						forced_height = dpi(55),
						buttons = {
							awful.button({}, 1, function()
								ret:refresh()
							end)
						}
					}
				},
				{
					id = "close_button",
					widget = widgets.hover_button {
						markup = text_icons.arrow_left,
						forced_width = dpi(55),
						forced_height = dpi(55),
					}
				}
			}
		}
	}

	ret.massage_widget = wibox.widget {
		widget = wibox.container.background,
		fg = beautiful.fg_alt,
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

	ret.connect_widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		spacing = dpi(15),
		{
			widget = wibox.container.background,
			bg = beautiful.bg_alt,
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
									id = "input_textbox",
									widget = wibox.widget.textbox
								}
							},
							nil,
							{
								id = "obscure",
								widget = wibox.widget.textbox
							}
						}
					},
					widgets.separator {
						dir = "h",
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
								id = "auto_connect",
								widget = wibox.widget.textbox
							}
						}
					}
				}
			}
		},
		{
			id = "connect_button",
			widget = widgets.hover_button {
				markup = "Connect",
				margins = dpi(10)
			}
		}
	}

	ret.passwd_text_input = widgets.text_input {
		textbox = ret.connect_widget:get_children_by_id("input_textbox")[1],
		placeholder = "Password",
		cursor_bg = beautiful.fg,
		cursor_fg = beautiful.bg,
		placeholder_fg = beautiful.fg_alt,
		obscure = true,
		done_callback = function()
			ret:close_ap_menu()
		end
	}

	ret.disconnect_widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		widgets.hover_button {
			markup = "Disonnect",
			margins = dpi(10),
			buttons = {
				awful.button({}, 1, function()
					network_daemon:disconnect_from_active_access_point()
					network_daemon:scan_access_points()
				end)
			}
		}
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
				id = "container",
				widget = wibox.container.background
			}
		}
	}

	ret.ap_menu:get_children_by_id("close")[1]:buttons {
		awful.button({}, 1, function()
			ret:close_ap_menu()
		end)
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
				{
					id = "aps_layout",
					layout = wibox.layout.overflow.vertical,
					scrollbar_enabled = false,
					step = 40
				}
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
