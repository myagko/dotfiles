local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local Launcher = require("ui.launcher")
local Day_info = require("ui.day_info")

local bar = {}

function bar.launcher_button()
	return wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.accent,
		fg = beautiful.background,
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		buttons = {
			awful.button({}, 1, function()
				Launcher:toggle()
			end)
		},
		{
			widget = wibox.container.margin,
			margins = { left = dpi(7), right = dpi(7) },
			{
				widget = wibox.widget.textbox,
				align = "center",
				text = text_icons.apps
			}
		}
	}
end

function bar.time()
	return wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		buttons = {
			awful.button({}, 1, function()
				Day_info:toggle()
			end)
		},
		{
			widget = wibox.container.margin,
			margins = { left = dpi(8), right = dpi(8) },
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(8),
				{
					widget = wibox.widget.textclock,
					format = "%b %d, %a"
				},
				helpers.ui.create_sep {
					orientation = "v",
					size = beautiful.sep_width,
					margins = { top = dpi(4), bottom = dpi(4) }
				},
				{
					widget = wibox.widget.textclock,
					format = "%H:%M"
				}
			}
		}
	}
end

function bar.tray()
	local inst = {}
	inst.visibility = false

	inst.revealer = wibox.widget {
		id = "revealer",
		widget = wibox.widget.textbox,
		text = text_icons.arrow_left
	}

	inst.systray = wibox.widget {
		widget = wibox.container.margin,
		margins = { top = dpi(4), bottom = dpi(4) },
		{
			widget = wibox.widget.systray
		}
	}

	inst.m_layout = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(8),
		inst.revealer
	}

	inst.m_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		{
			widget = wibox.container.margin,
			margins = { left = dpi(8), right = dpi(8) },
			inst.m_layout
		}
	}

	inst.revealer:buttons {
		awful.button({}, 1, function()
			if not inst.visibility then
				inst.visibility = true
				inst.m_layout:insert(2, inst.systray)
				inst.revealer.text = text_icons.arrow_right
			else
				inst.visibility = false
				inst.m_layout:remove(2)
				inst.revealer.text = text_icons.arrow_left
			end
		end)
	}

	return inst.m_widget
end

function bar.kblayout()
	return wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		{
			widget = awful.widget.keyboardlayout {}
		}
	}
end

function bar.taglist(s)
	local inst = awful.widget.taglist {
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = {
			awful.button({ }, 1, function(t)
				t:view_only()
			end),
			awful.button({ }, 4, function(t)
				awful.tag.viewprev(t.screen)
			end),
			awful.button({ }, 5, function(t)
				awful.tag.viewnext(t.screen)
			end)
		},
		layout = {
			layout = wibox.layout.fixed.horizontal
		},
		widget_template = {
			widget = wibox.container.background,
			id = "t_container",
			{
				widget = wibox.container.margin,
				margins = { left = dpi(8), right = dpi(8) },
				{
					widget = wibox.widget.textbox,
					id = "t_index"
				}
			}
		}
	}

	local function t_callback(widget, tag, index, objects)
		local t_container = widget:get_children_by_id("t_container")[1]
		local t_index = widget:get_children_by_id("t_index")[1]

		t_index.text = tag.index

		if tag.selected then
			t_container.bg = beautiful.accent
			t_container.fg = beautiful.background
		elseif #tag:clients() > 0 then
			t_container.bg = beautiful.background_alt
			t_container.fg = beautiful.foreground
		else
			t_container.bg = beautiful.background_alt
			t_container.fg = beautiful.foreground_alt
		end

		for _, client in ipairs(tag:clients()) do
			if client.urgent then
				t_container.bg = beautiful.red
				t_container.fg = beautiful.background
				break
			end
		end
	end

	inst.widget_template.create_callback = function(widget, tag, index, objects)
		t_callback(widget, tag, index, objects)
	end

	inst.widget_template.update_callback = function(widget, tag, index, objects)
		t_callback(widget, tag, index, objects)
	end

	return {
		widget = wibox.container.background,
		border_width = beautiful.comp_border_width,
		border_color = beautiful.border_color,
		inst
	}
end

function bar.tasklist(s)
	local inst = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = {
			awful.button({ }, 1, function(c)
				c:activate { context = "tasklist", action = "toggle_minimization" }
			end),
			awful.button({ }, 2, function(c)
				c:kill { context = "tasklist", action = "close client" }
			end)
		},
		layout = {
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(7),
		},
		widget_template = {
			widget = wibox.container.background,
			border_width = beautiful.comp_border_width,
			border_color = beautiful.border_color,
			id = "c_container",
			{
				layout = wibox.layout.align.vertical,
				nil,
				{
					widget = wibox.container.margin,
					margins = { left = dpi(8), right = dpi(8) },
					{
						widget = wibox.container.constraint,
						strategy = "max",
						width = 300,
						{
							widget = wibox.widget.textbox,
							id = "c_name"
						}
					}
				},
				{
					widget = wibox.container.background,
					id = "c_selection",
					forced_height = dpi(3),
					bg = beautiful.accent
				}
			}
		}
	}

	local function c_callback(widget, client, index, objects)
		local c_container = widget:get_children_by_id("c_container")[1]
		local c_selection = widget:get_children_by_id("c_selection")[1]
		local c_name = widget:get_children_by_id("c_name")[1]

		c_name.text = client.class
		c_container.bg = beautiful.background_alt

		if client.minimized then
			c_container.fg = beautiful.foreground_alt
		else
			c_container.fg = beautiful.foreground
		end

		if client.active then
			c_selection.forced_height = dpi(3)
		else
			c_selection.forced_height = 0
		end
	end

	inst.widget_template.create_callback = function(widget, client, index, objects)
		c_callback(widget, client, index, objects)

		local c_tooltip = awful.tooltip {
			objects = { widget },
			timer_function = function() return client.name end,
			mode = "outside",
			border_width = beautiful.border_width,
			border_color = beautiful.border_color,
			margins = { top = dpi(5), bottom = dpi(5), left = dpi(8), right = dpi(8) },
			gaps = { bottom = beautiful.useless_gap }
		}

		client:connect_signal("request::activate", function()
			if client.fullscreen then
				c_tooltip.visible = false
			end
		end)

		client:connect_signal("request::geometry", function()
			if client.fullscreen then
				c_tooltip.visible = false
			end
		end)
	end

	inst.widget_template.update_callback = function(widget, client, index, objects)
		c_callback(widget, client, index, objects)
	end

	return inst
end

function bar:set_secondary(s)
	return awful.wibar {
		position = "bottom",
		screen = s,
		height = dpi(45) + beautiful.border_width,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.background_urgent,
			{
				widget = wibox.container.margin,
				margins = { top = beautiful.border_width },
				{
					widget = wibox.container.background,
					bg = beautiful.background,
					{
						layout = wibox.layout.fixed.horizontal,
						{
							widget = wibox.container.margin,
							margins = dpi(7),
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(7),
								self.taglist(s),
								self.tasklist(s),
							}
						}
					}
				}
			}
		}
	}
end

function bar:set_primary(s)
	return awful.wibar {
		position = "bottom",
		screen = s,
		height = dpi(45) + beautiful.border_width,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.background_urgent,
			{
				widget = wibox.container.margin,
				margins = { top = beautiful.border_width },
				{
					widget = wibox.container.background,
					bg = beautiful.background,
					{
						layout = wibox.layout.align.horizontal,
						nil,
						{
							widget = wibox.container.margin,
							margins = dpi(7),
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(7),
								self.taglist(s),
								self.tasklist(s),
							}
						},
						{
							widget = wibox.container.margin,
							margins = { top = dpi(7), bottom = dpi(7), left = 0, right = dpi(7) },
							{
								layout = wibox.layout.fixed.horizontal,
								spacing = dpi(7),
								self.tray(),
								self.kblayout(),
								self.time(),
								self.launcher_button()
							}
						}
					}
				}
			}
		}
	}
end

return bar
