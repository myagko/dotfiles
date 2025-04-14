local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local common = require("common")
local network = require("services.network")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi

local wifi_applet = {}
local instance = nil

local function create_ap_widget(ap, self)
	local is_active = ap == network.wireless:get_active_access_point()
	local ssid = ap:get_ssid()
	local strength = ap:get_strength()

	local name = wibox.widget {
		widget = wibox.widget.textbox,
		markup = is_active and ssid .. " " .. text_icons.check or ssid
	}

	local strenght = wibox.widget {
		widget = wibox.widget.textbox,
		markup = strength > 70 and "▂▄▆█"
			or strength > 45 and "▂▄▆"
			or strength > 20 and "▂▄"
			or "▂"
	}

	local ap_widget = wibox.widget {
		active = is_active,
		widget = wibox.container.background,
		shape = beautiful.rrect(dpi(10)),
		{
			widget = wibox.container.margin,
			forced_height = dpi(50),
			margins = dpi(15),
			buttons = {
				awful.button({}, 1, function()
					self:open_ap_menu(ap)
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

local function on_scan_success(aps, self)
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]
	self.ap_widgets = {}
	aps_layout:reset()

	for _, ap in pairs(aps) do
		local ap_widget = create_ap_widget(ap, self)
		table.insert(self.ap_widgets, ap_widget)

		if ap == network.wireless:get_active_access_point() then
			aps_layout:insert(1, ap_widget)
		else
			aps_layout:add(ap_widget)
		end
	end
end

local function on_state_changed(state, self)
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]
	local control_button_sep = self.control_button:get_children_by_id("separator")[1]
	local control_button_label = self.control_button:get_children_by_id("label")[1]
	local bottombar_toggle_button = self.bottombar:get_children_by_id("toggle_button")[1]
	self.ap_widgets = {}

	if state then
		bottombar_toggle_button:set_text(text_icons.switch_on)
		self.control_button:set_bg(beautiful.ac)
		self.control_button:set_fg(beautiful.bg)
		control_button_sep:set_color(beautiful.bg)
		control_button_label:set_markup("Enabled")
		aps_layout:reset()
		aps_layout:add(self.massage_widget)
		self.massage_widget:set_text(text_icons.wait)
		gtimer.start_new(5, function()
			network.wireless:scan_access_points()
			return false
		end)
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

function wifi_applet:open_ap_menu(ap)
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
	ap_menu_title:set_markup(ap:get_ssid())

	connect_widget_obscure:set_markup(text_icons.eye_off)
	connect_widget_obscure:buttons {
		awful.button({}, 1, function()
			obscure = not obscure
			self.passwd_text_input:set_obscure(obscure)
			if obscure then
				connect_widget_obscure:set_markup(text_icons.eye_off)
			else
				connect_widget_obscure:set_markup(text_icons.eye_on)
			end
		end)
	}

	connect_widget_auto_connect:set_markup(text_icons.check_on)
	connect_widget_auto_connect:buttons {
		awful.button({}, 1, function()
			auto_connect = not auto_connect
			if auto_connect then
				connect_widget_auto_connect:set_markup(text_icons.check_on)
			else
				connect_widget_auto_connect:set_markup(text_icons.check_off)
			end
		end)
	}

	if ap == network.wireless:get_active_access_point() then
		ap_menu_container:set_widget(self.disconnect_widget)
	else
		ap_menu_container:set_widget(self.connect_widget)
		self.passwd_text_input.exe_callback = function(input)
			network:connect_access_point(ap, input, auto_connect)
		end
		connect_widget_connect_button:buttons {
			awful.button({}, 1, function()
				network:connect_access_point(ap, self.passwd_text_input:get_input(), auto_connect)
				self:close_ap_menu()
			end)
		}
		self.passwd_text_input:run_keygrabber()
	end
end

function wifi_applet:close_ap_menu()
	local aps_layout = self.main_widget:get_children_by_id("aps_layout")[1]

	if network:get_wireless_state() then
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
	network.wireless:scan_access_points()
end

local function new()
	local ret = {}
	gtable.crush(ret, wifi_applet, true)
	ret.ap_widgets = {}

	ret.control_button = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(55),
		bg = beautiful.bg_alt,
		fg = beautiful.fg,
		shape = beautiful.rrect(dpi(10)),
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
							network:set_wireless_state(not network:get_wireless_state())
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
						widget = wibox.container.margin,
						forced_height = 1,
						forced_width = beautiful.separator_thickness,
						margins = { top = dpi(12), bottom = dpi(12) },
						{
							id = "separator",
							widget = wibox.widget.separator,
							orientation = "vertical"
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
		if not network:get_wireless_state() then
			w:set_bg(beautiful.bg_urg)
			w:get_children_by_id("separator")[1]:set_color(beautiful.fg_alt)
		end
	end)

	ret.control_button:connect_signal("mouse::leave", function(w)
		if not network:get_wireless_state() then
			w:set_bg(beautiful.bg_alt)
			w:get_children_by_id("separator")[1]:set_color(beautiful.bg_urg)
		end
	end)

	ret.bottombar = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(55),
		bg = beautiful.bg_alt,
		shape = beautiful.rrect(dpi(10)),
		{
			layout = wibox.layout.align.horizontal,
			{
				id = "toggle_button",
				widget = common.hover_button {
					forced_width = dpi(55),
					forced_height = dpi(55),
					shape = beautiful.rrect(dpi(10)),
					buttons = {
						awful.button({}, 1, function()
							network:set_wireless_state(not network:get_wireless_state())
						end)
					}
				}
			},
			nil,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = beautiful.separator_thickness + dpi(2),
				spacing_widget = {
					widget = wibox.container.margin,
					margins = { top = dpi(12), bottom = dpi(12) },
					{
						widget = wibox.widget.separator,
						orientation = "vertical"
					}
				},
				{
					id = "refresh_button",
					widget = common.hover_button {
						markup = text_icons.reboot,
						forced_width = dpi(55),
						forced_height = dpi(55),
						shape = beautiful.rrect(dpi(10)),
						buttons = {
							awful.button({}, 1, function()
								if network:get_wireless_state() then
									ret:refresh()
								end
							end)
						}
					}
				},
				{
					id = "close_button",
					widget = common.hover_button {
						markup = text_icons.arrow_left,
						forced_width = dpi(55),
						forced_height = dpi(55),
						shape = beautiful.rrect(dpi(10))
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
			shape = beautiful.rrect(dpi(10)),
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
								widget = wibox.container.constraint,
								forced_width = dpi(310),
								strategy = "max",
								height = dpi(25),
								{
									id = "input_textbox",
									widget = wibox.widget.textbox,
									ellipsize = "start"
								}
							},
							nil,
							{
								id = "obscure",
								widget = wibox.widget.textbox
							}
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
			widget = common.hover_button {
				margins = dpi(10),
				shape = beautiful.rrect(dpi(10)),
				markup = "Connect"
			}
		}
	}

	ret.passwd_text_input = common.text_input {
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
		common.hover_button {
			markup = "Disonnect",
			margins = dpi(10),
			shape = beautiful.rrect(dpi(10)),
			buttons = {
				awful.button({}, 1, function()
					network:disconnect_active_access_point()
					network.wireless:scan_access_points()
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
			spacing = dpi(8),
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

	network.wireless:connect_signal("scan_access_points_success", function()
		on_scan_success(network.wireless:get_access_points(), ret)
	end)

	network:connect_signal("wireless_state", function(_, state)
		on_state_changed(state, ret)
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
