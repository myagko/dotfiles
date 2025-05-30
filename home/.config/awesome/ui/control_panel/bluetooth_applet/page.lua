local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local common = require("common")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi
local bluetooth = require("service.bluetooth").get_default()

local function create_dev_widget(path)
	local dev = bluetooth:get_device(path)

	local name = wibox.widget {
		widget = wibox.widget.textbox
	}

	local percentage = wibox.widget {
		widget = wibox.widget.textbox
	}

	local connect_button = common.hover_button {
		margins = { left = dpi(15), right = dpi(15) },
		shape = beautiful.rrect(dpi(10))
	}

	local pair_button = common.hover_button {
		margins = { left = dpi(15), right = dpi(15) },
		shape = beautiful.rrect(dpi(10))
	}

	local trust_button = common.hover_button {
		margins = { left = dpi(15), right = dpi(15) },
		shape = beautiful.rrect(dpi(10))
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
		shape = beautiful.rrect(dpi(10)),
		{
			widget = wibox.container.margin,
			margins = { left = dpi(15), right = dpi(15) },
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
					{
						widget = wibox.container.constraint,
						width = dpi(130),
						percentage
					}
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
			dev:toggle_connect()
		end)
	}

	pair_button:buttons {
		awful.button({}, 1, function()
			dev:toggle_pair()
		end)
	}

	trust_button:buttons {
		awful.button({}, 1, function()
			dev:toggle_trust()
		end)
	}

	dev:connect_signal("property::percentage", function(_, perc)
		percentage:set_markup(perc ~= nil and string.format("%.0f%%", perc) or "")
	end)

	dev:connect_signal("property::connected", function(_, cnd)
		name:set_markup(dev:get_name() .. (cnd and " " .. text_icons.check or ""))
		connect_button:set_label(cnd and "Disconnect" or "Connect")
	end)

	dev:connect_signal("property::paired", function(_, prd)
		pair_button:set_label(prd and "Unpair" or "Pair")
	end)

	dev:connect_signal("property::trusted", function(_, trd)
		trust_button:set_label(trd and "Untrust" or "Trust")
	end)

	name:set_markup(dev:get_name() .. (dev:get_connected() and " " .. text_icons.check or ""))
	percentage:set_markup(dev:get_percentage() ~= nil and string.format("%.0f%%", dev:get_percentage()) or "")
	connect_button:set_label(dev:get_connected() and "Disconnect" or "Connect")
	pair_button:set_label(dev:get_paired() and "Unpair" or "Pair")
	trust_button:set_label(dev:get_trusted() and "Untrust" or "Trust")

	return dev_widget
end

local function on_device_added(self, path)
	local devs_layout = self:get_children_by_id("devices-layout")[1]
	local dev_widget = create_dev_widget(path)

	if #devs_layout.children == 1 and not devs_layout.children[1].path then
		devs_layout:reset()
		devs_layout:add(dev_widget)
	else
		for _, old_dev_widget in ipairs(devs_layout.children) do
			if old_dev_widget.path == path then
				devs_layout:remove_widgets(old_dev_widget)
			end
		end
		devs_layout:add(dev_widget)
	end
end

local function on_device_removed(self, path)
	local devs_layout = self:get_children_by_id("devices-layout")[1]
	for _, dev_w in ipairs(devs_layout.children) do
		if dev_w.path == path then
			devs_layout:remove_widgets(dev_w)
		end
	end

	if #devs_layout.children == 0 then
		devs_layout:add(wibox.widget {
			widget = wibox.container.background,
			fg = beautiful.fg_alt,
			forced_height = dpi(400),
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = beautiful.font_h2,
				markup = text_icons.wait
			}
		})
	end
end

local function on_discovering(self, discovering)
	local bottombar_discover_button = self:get_children_by_id("bottombar-discover-button")[1]
	bottombar_discover_button:set_fg_normal(discovering and beautiful.fg_alt or beautiful.fg)
	bottombar_discover_button:set_bg_hover(discovering and beautiful.fg_alt or beautiful.ac)
	bottombar_discover_button:set_fg(discovering and beautiful.fg_alt or beautiful.fg)
	bottombar_discover_button:set_bg(beautiful.bg_alt)
end

local function on_state_changed(self, state)
	local devs_layout = self:get_children_by_id("devices-layout")[1]
	local bottombar_toggle_button = self:get_children_by_id("bottombar-toggle-button")[1]
	local bottombar_discover_button = self:get_children_by_id("bottombar-discover-button")[1]

	on_discovering(self, bluetooth:get_discovering())

	if state then
		bottombar_toggle_button:set_label(text_icons.switch_on)
		devs_layout:reset()
		devs_layout:add(wibox.widget {
			widget = wibox.container.background,
			fg = beautiful.fg_alt,
			forced_height = dpi(400),
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = beautiful.font_h2,
				markup = text_icons.wait
			}
		})
		for _, dev in pairs(bluetooth:get_devices()) do
			on_device_added(self, dev:get_path())
		end
	else
		bottombar_toggle_button:set_label(text_icons.switch_off)
		bottombar_discover_button:set_fg(beautiful.fg)
		bottombar_discover_button:set_bg(beautiful.bg_alt)
		devs_layout:reset()
		devs_layout:add(wibox.widget {
			widget = wibox.container.background,
			fg = beautiful.fg_alt,
			forced_height = dpi(400),
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = beautiful.font_h2,
				markup = "Bluetooth disabled"
			}
		})
	end
end

local function new()
	local ret = wibox.widget {
		widget = wibox.container.background,
		{
			layout = wibox.layout.fixed.vertical,
			spacing = dpi(8),
			{
				widget = wibox.container.background,
				forced_height = dpi(400),
				forced_width = dpi(400),
				{
					id = "devices-layout",
					layout = wibox.layout.overflow.vertical,
					scrollbar_enabled = false,
					step = 40,
					spacing = dpi(3)
				}
			},
			{
				widget = wibox.container.background,
				forced_height = dpi(55),
				bg = beautiful.bg_alt,
				shape = beautiful.rrect(dpi(10)),
				{
					layout = wibox.layout.align.horizontal,
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
							id = "bottombar-toggle-button",
							widget = common.hover_button {
								forced_width = dpi(55),
								forced_height = dpi(55),
								shape = beautiful.rrect(dpi(10))
							}
						},
						{
							id = "bottombar-discover-button",
							widget = common.hover_button {
								label = text_icons.search,
								forced_width = dpi(55),
								forced_height = dpi(55),
								shape = beautiful.rrect(dpi(10))
							}
						}
					},
					nil,
					{
						id = "bottombar-close-button",
						widget = common.hover_button {
							label = text_icons.arrow_left,
							forced_width = dpi(55),
							forced_height = dpi(55),
							shape = beautiful.rrect(dpi(10))
						}
					}
				}
			}
		}
	}

	local bottombar_toggle_button = ret:get_children_by_id("bottombar-toggle-button")[1]
	bottombar_toggle_button:buttons {
		awful.button({}, 1, function()
			bluetooth:set_state(not bluetooth:get_state())
		end)
	}

	local bottombar_discover_button = ret:get_children_by_id("bottombar-discover-button")[1]
	bottombar_discover_button:buttons {
		awful.button({}, 1, function()
			if bluetooth:get_state() then
				if bluetooth:get_discovering() then
					bluetooth:stop_discovery()
				else
					bluetooth:start_discovery()
				end
			end
		end)
	}

	bluetooth:connect_signal("device-added", function(_, path)
		on_device_added(ret, path)
	end)

	bluetooth:connect_signal("device-removed", function(_, path)
		on_device_removed(ret, path)
	end)

	bluetooth:connect_signal("property::discovering", function(_, dsc)
		on_discovering(ret, dsc)
	end)

	bluetooth:connect_signal("bluetooth-state", function(_, state)
		on_state_changed(ret, state)
	end)

	on_state_changed(ret, bluetooth:get_state())

	return ret
end

return setmetatable({
	new = new
}, {
	__call = new
})
