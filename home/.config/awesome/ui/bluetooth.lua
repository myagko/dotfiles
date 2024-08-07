local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local bluetooth_daemon = require("daemons.bluetooth")
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
						bluetooth_daemon:toggle()
					end)
				},
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(10),
					{
						widget = wibox.widget.textbox,
						text = text_icons.bluetooth_on
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
			applet.main_layout:reset()
			bluetooth_daemon:scan()
		end)
	}
}

applet.bottombar_toggle_button = helpers.ui.create_hover_button {
	forced_width = dpi(55),
	forced_height = dpi(55),
	font = helpers.ui.font(beautiful.font_size + dpi(5)),
	buttons = {
		awful.button({}, 1, function()
			bluetooth_daemon:toggle()
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

applet.dev_menu = wibox.widget {
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
					widget = wibox.widget.textbox,
				}
			}
		},
		{
			layout = wibox.layout.fixed.vertical,
			applet.connect_button
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

function applet:crate_dev_widget(device, path)
	local name = wibox.widget {
		widget = wibox.widget.textbox,
		text = device:get_name()
	}

	local connect_button = helpers.ui.create_hover_button {
		text = "Connect",
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		margins = dpi(15)
	}

	local trust_button = helpers.ui.create_hover_button {
		text = "Trust",
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		margins = dpi(15)
	}

	local pair_button = helpers.ui.create_hover_button {
		text = "Pair",
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		margins = dpi(15)
	}

	local buttons_widget = wibox.widget {
		widget = wibox.container.background,
		{
			layout = wibox.layout.flex.horizontal,
			connect_button,
			trust_button,
			pair_button
		}
	}

	local inst = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(40),
		{
			widget = wibox.container.margin,
			margins = dpi(5),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(10),
				{
					id = "dev_head",
					widget = wibox.container.background,
					name
				},
				{
					id = "dev_layout",
					layout = wibox.layout.fixed.horizontal
				}
			}
		},
		get_layout = function(widget)
			return widget:get_children_by_id("dev_layout")[1]
		end,
		get_head = function(widget)
			return widget:get_children_by_id("dev_head")[1]
		end
	}

	local connect_widget_visible = false

	local function set_connect_widget()
		connect_widget_visible = not connect_widget_visible
		if connect_widget_visible then
			inst:get_layout():add(buttons_widget)
			inst.forced_height = dpi(60)
		else
			inst:get_layout():reset()
			inst.forced_height = dpi(40)
		end
	end

	inst:get_head():buttons {
		awful.button({}, 1, function()
			set_connect_widget()
		end)
	}

	connect_button:buttons {
		awful.button({}, 1, function()
			device:toggle_connect()
		end)
	}

	trust_button:buttons {
		awful.button({}, 1, function()
			device:toggle_trust()
		end)
	}

	trust_button:buttons {
		awful.button({}, 1, function()
			device:toggle_pair()
		end)
	}

	bluetooth_daemon:connect_signal(path .. "_updated", function(daemon)
		connect_button:set_text(device:is_connected() and "Disconnect" or "Connect")
		trust_button:set_text(device:is_trusted() and "Untrust" or "Trust")
		pair_button:set_text(device:is_paired() and "Unpair" or "Pair")
	end)

	return inst
end

function applet:on_device_changed(device, path)
	local dev_widget = self:crate_dev_widget(device, path)
	self.main_layout:add(dev_widget)

	bluetooth_daemon:connect_signal(path .. "_removed", function(daemon)
		self.main_layout:remove_widgets(dev_widget)
	end)
end

function applet:on_state_changed(state)
	if state then
		self.bottombar_toggle_button:set_text(text_icons.switch_on)
		self.control_button:get_label().text = "Enabled"
		self.control_button.bg = beautiful.accent
		self.control_button.fg = beautiful.background
		self.main_layout:reset()
	else
		self.bottombar_toggle_button:set_text(text_icons.switch_off)
		self.control_button:get_label().text = "Disabled"
		self.control_button.bg = beautiful.background_alt
		self.control_button.fg = beautiful.foreground
		self.main_layout:reset()
		self.main_layout:add(self.massage_widget)
		self.massage_widget:set_text("Bluetooth Disabled")
	end
end

bluetooth_daemon:connect_signal("new_device", function(daemon, device, path)
	applet:on_device_changed(device, path)
end)

bluetooth_daemon:connect_signal("state", function(daemon, state)
	applet:on_state_changed(state)
end)

applet.bottombar_toggle_button:set_text(text_icons.switch_off)
applet.control_button:get_label().text = "Disabled"
applet.control_button.bg = beautiful.background_alt
applet.control_button.fg = beautiful.foreground
applet.main_layout:reset()
applet.main_layout:add(applet.massage_widget)
applet.massage_widget:set_text("Bluetooth Disabled")

return applet
