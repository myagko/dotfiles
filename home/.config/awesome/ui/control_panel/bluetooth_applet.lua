local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local widgets = require("widgets")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local bluetooth_daemon = require("daemons.bluetooth")

local bluetooth_applet = {}
local instance = nil

local function create_dev_widget(device, path)
	local name = wibox.widget {
		widget = wibox.widget.textbox,
		markup = device:is_connected() and device:get_name() .. " " .. text_icons.check
			or device:get_name()
	}

	local icon = wibox.widget {
		widget = wibox.widget.textbox,
		markup = helpers.create_markup(device:get_icon(), { fg = beautiful.fg_alt })
	}

	local connect_button = widgets.hover_button {
		markup = "Connect",
		margins = dpi(5)
	}

	local pair_button = widgets.hover_button {
		markup = "Pair",
		margins = dpi(5)
	}

	local trust_button = widgets.hover_button {
		markup = "Trust",
		margins = dpi(5)
	}

	local buttons_widget = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(50),
		{
			widget = wibox.container.margin,
			margins = { top = dpi(5), bottom = dpi(5) },
			{
				layout = wibox.layout.flex.horizontal,
				spacing = dpi(5),
				connect_button,
				pair_button,
				trust_button
			}
		}
	}

	local dev_widget_header = wibox.widget {
		widget = wibox.container.background,
		forced_height = dpi(40),
		{
			widget = wibox.container.margin,
			margins = { left = dpi(10), right = dpi(10) },
			{
				layout = wibox.layout.align.horizontal,
				{
					widget = wibox.container.constraint,
					width = dpi(200),
					name
				},
				nil,
				{
					widget = wibox.container.constraint,
					width = dpi(130),
					icon
				}
			}
		}
	}

	local dev_widget_layout = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		dev_widget_header
	}

	local dev_widget = wibox.widget {
		path = path,
		widget = wibox.container.background,
		forced_height = dpi(40),
		dev_widget_layout
	}

	dev_widget_header:connect_signal("mouse::enter", function(w)
		w:set_bg(beautiful.bg_urg)
	end)

	dev_widget_header:connect_signal("mouse::leave", function(w)
		w:set_bg(beautiful.bg)
	end)

	local connect_widget_visible = false

	local function set_connect_widget()
		connect_widget_visible = not connect_widget_visible
		if connect_widget_visible then
			dev_widget_layout:add(buttons_widget)
			dev_widget:set_forced_height(dpi(90))
		else
			dev_widget_layout:remove_widgets(buttons_widget)
			dev_widget:set_forced_height(dpi(40))
		end
	end

	dev_widget_header:buttons {
		awful.button({}, 1, function()
			set_connect_widget()
		end)
	}

	connect_button:buttons {
		awful.button({}, 1, function()
			device:toggle_connect()
		end)
	}

	pair_button:buttons {
		awful.button({}, 1, function()
			device:toggle_pair()
		end)
	}

	trust_button:buttons {
		awful.button({}, 1, function()
			device:toggle_trust()
		end)
	}

	local function on_update()
		connect_button:set_text(device:is_connected() and "Disconnect" or "Connect")
		pair_button:set_text(device:is_paired() and "Unpair" or "Pair")
		trust_button:set_text(device:is_trusted() and "Untrust" or "Trust")
	end

	bluetooth_daemon:connect_signal(path .. "_updated", function()
		on_update()
	end)

	on_update()

	return dev_widget
end

function bluetooth_applet:on_new_device(device, path)
	local devs_layout = self.main_widget:get_children_by_id("devs_layout")[1]
	local dev_widget = create_dev_widget(device, path)

	if devs_layout.children[1] == self.massage_widget then
		devs_layout:replace_widget(self.massage_widget, dev_widget)
	else
		for _, old_dev_widget in ipairs(devs_layout.children) do
			if old_dev_widget.path == path then
				devs_layout:remove_widgets(old_dev_widget)
			end
		end
		devs_layout:add(dev_widget)
	end

	bluetooth_daemon:connect_signal(path .. "_removed", function()
		devs_layout:remove_widgets(dev_widget)
		if #devs_layout.children == 0 then
			devs_layout:add(self.massage_widget)
			self.massage_widget:set_text(text_icons.wait)
		end
	end)
end

function bluetooth_applet:on_state_changed(state)
	local control_button_sep = self.control_button:get_children_by_id("separator")[1]
	local control_button_label = self.control_button:get_children_by_id("label")[1]
	local bottombar_toggle_button = self.bottombar:get_children_by_id("toggle_button")[1]
	local devs_layout = self.main_widget:get_children_by_id("devs_layout")[1]

	if state then
		bottombar_toggle_button:set_text(text_icons.switch_on)
		self.control_button:set_bg(beautiful.accent)
		self.control_button:set_fg(beautiful.bg)
		control_button_sep:set_color(beautiful.bg)
		control_button_label:set_markup("Enabled")
		devs_layout:reset()
		devs_layout:add(self.massage_widget)
		self.massage_widget:set_text(text_icons.wait)
	else
		bottombar_toggle_button:set_text(text_icons.switch_off)
		self.control_button:set_bg(beautiful.bg_alt)
		self.control_button:set_fg(beautiful.fg)
		control_button_sep:set_color(beautiful.bg_urg)
		control_button_label:set_markup("Disabled")
		devs_layout:reset()
		devs_layout:add(self.massage_widget)
		self.massage_widget:set_text("Bluetooth disabled")
	end
end

local function new()
	local ret = {}
	gtable.crush(ret, bluetooth_applet, true)

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
							bluetooth_daemon:toggle()
						end)
					},
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = dpi(10),
						{
							widget = wibox.widget.textbox,
							markup = text_icons.bluetooth
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
		if not bluetooth_daemon:get_powered() then
			w:set_bg(beautiful.bg_urg)
			w:get_children_by_id("separator")[1]:set_color(beautiful.fg_alt)
		end
	end)

	ret.control_button:connect_signal("mouse::leave", function(w)
		if not bluetooth_daemon:get_powered() then
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
							bluetooth_daemon:toggle()
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
								bluetooth_daemon:scan()
							end)
						}
					}
				},
				{
					id = "close_button",
					widget = widgets.hover_button {
						markup = text_icons.arrow_left,
						forced_width = dpi(55),
						forced_height = dpi(55)
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

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(10),
			{
				widget = wibox.container.background,
				forced_height = dpi(400),
				forced_width = dpi(400),
				{
					id = "devs_layout",
					layout = wibox.layout.overflow.vertical,
					scrollbar_enabled = false,
					step = 40
				}
			},
			ret.bottombar
		}
	}

	bluetooth_daemon:connect_signal("new_device", function(_, device, path)
		ret:on_new_device(device, path)
	end)

	bluetooth_daemon:connect_signal("state", function(_, state)
		ret:on_state_changed(state)
	end)

	ret:on_state_changed(false)

	return ret
end

if not instance then
	instance = new()
end

return instance
