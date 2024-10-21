local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local launcher = require("ui.launcher")
local day_info = require("ui.day_info")

local bar = {}

function bar.launcher_button()
	local widget = wibox.widget {
		widget = wibox.container.background,
		buttons = {
			awful.button({}, 1, function()
				launcher:toggle()
			end)
		},
		{
			widget = wibox.widget.imagebox,
			scaling_quality = "nearest",
			image = beautiful.awesome_icon
		}
	}

	return widget
end

function bar.time()
	local sep = helpers.ui.create_sep {
		orientation = "v",
		size = beautiful.sep_width,
		margins = { top = dpi(4), bottom = dpi(4) }
	}

	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		buttons = {
			awful.button({}, 1, function()
				day_info:toggle()
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
					format = "%d %b, %a"
				},
				sep,
				{
					widget = wibox.widget.textclock,
					format = "%H:%M"
				}
			}
		}
	}

	widget:connect_signal("mouse::enter", function(w)
		w.bg = beautiful.background_urgent
		sep:set_color(beautiful.foreground_alt)
	end)

	widget:connect_signal("mouse::leave", function(w)
		w.bg = beautiful.background_alt
		sep:set_color(beautiful.background_urgent)
	end)

	return widget
end

function bar.tray()
	local visibility = false

	local revealer = wibox.widget {
		widget = wibox.widget.textbox,
		markup = text_icons.arrow_left
	}

	local systray = wibox.widget {
		widget = wibox.container.margin,
		margins = { top = dpi(4), bottom = dpi(4) },
		{
			widget = wibox.widget.systray
		}
	}

	local layout = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(8),
		revealer
	}

	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		{
			widget = wibox.container.margin,
			margins = { left = dpi(8), right = dpi(8) },
			layout
		}
	}

	revealer:buttons {
		awful.button({}, 1, function()
			if not visibility then
				visibility = true
				layout:insert(2, systray)
				revealer.markup = text_icons.arrow_right
			else
				visibility = false
				layout:remove(2)
				revealer.markup = text_icons.arrow_left
			end
		end)
	}

	widget:connect_signal("mouse::enter", function(w)
		beautiful.bg_systray = beautiful.background_urgent
		w.bg = beautiful.background_urgent
	end)

	widget:connect_signal("mouse::leave", function(w)
		beautiful.bg_systray = beautiful.background_alt
		w.bg = beautiful.background_alt
	end)

	return widget
end

function bar.kblayout()
	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		{
			widget = awful.widget.keyboardlayout {}
		}
	}

	widget:connect_signal("mouse::enter", function(w)
		w.bg = beautiful.background_urgent
	end)

	widget:connect_signal("mouse::leave", function(w)
		w.bg = beautiful.background_alt
	end)

	return widget
end

function bar.layoutbox(s)
	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		buttons = {
			awful.button({ }, 1, function()
				awful.layout.inc(1)
			end)
		},
		{
			widget = wibox.container.margin,
			margins = dpi(7),
			{
				widget = awful.widget.layoutbox {
					screen = s
				}
			}
		}
	}

	widget:connect_signal("mouse::enter", function(w)
		w.bg = beautiful.background_urgent
	end)

	widget:connect_signal("mouse::leave", function(w)
		w.bg = beautiful.background_alt
	end)

	return widget
end

function bar.taglist(s)
	local taglist = awful.widget.taglist {
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

	local function t_callback(widget, tag, _, _)
		local t_container = widget:get_children_by_id("t_container")[1]
		local t_index = widget:get_children_by_id("t_index")[1]

		t_index.markup = tag.index

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
				t_container.fg = beautiful.red
				break
			end
		end
	end

	taglist.widget_template.create_callback = function(widget, tag, index, objects)
		t_callback(widget, tag, index, objects)

		widget:connect_signal("mouse::enter", function(w)
			if not tag.selected then
				w.bg = beautiful.background_urgent
			end
		end)

		widget:connect_signal("mouse::leave", function(w)
			if not tag.selected then
				w.bg = beautiful.background_alt
			end
		end)
	end

	taglist.widget_template.update_callback = function(widget, tag, index, objects)
		t_callback(widget, tag, index, objects)
	end

	return taglist
end

function bar.tasklist(s)
	local tasklist = awful.widget.tasklist {
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
			id = "c_container",
			widget = wibox.container.background,
			{
				layout = wibox.layout.align.vertical,
				nil,
				{
					widget = wibox.container.margin,
					margins = { left = dpi(8), right = dpi(8) },
					{
						widget = wibox.container.constraint,
						strategy = "max",
						width = dpi(150),
						{
							id = "c_name",
							widget = wibox.widget.textbox,
							align = "center"
						}
					}
				},
				{
					widget = wibox.container.background,
					id = "c_selection",
					bg = beautiful.accent
				}
			}
		}
	}

	local function c_callback(widget, client, _, _)
		local c_container = widget:get_children_by_id("c_container")[1]
		local c_selection = widget:get_children_by_id("c_selection")[1]
		local c_name = widget:get_children_by_id("c_name")[1]

		c_name.markup = client.class or "no class"
		c_container.bg = beautiful.background_alt

		if client.minimized then
			c_container.fg = beautiful.foreground_alt
		else
			c_container.fg = beautiful.foreground
		end

		if client.active then
			c_selection.forced_height = dpi(2)
		else
			c_selection.forced_height = 0
		end
	end

	tasklist.widget_template.create_callback = function(widget, client, index, objects)
		c_callback(widget, client, index, objects)

		--[[
		local c_tooltip = awful.tooltip {
			objects = { widget },
			mode = "outside",
			border_width = beautiful.border_width,
			border_color = beautiful.border_color,
			margins = { top = dpi(5), bottom = dpi(5), left = dpi(8), right = dpi(8) },
			gaps = { bottom = beautiful.useless_gap },
			timer_function = function() return client.name end
		}

		client:connect_signal("property::fullscreen", function(c)
			if c.fullscreen then
				c_tooltip.visible = false
			end
		end)

		client:connect_signal("property::minimized", function(c)
			if c.fullscreen then
				c_tooltip.visible = false
			end
		end)
		]]

		widget:connect_signal("mouse::enter", function(w)
			w.bg = beautiful.background_urgent
		end)

		widget:connect_signal("mouse::leave", function(w)
			w.bg = beautiful.background_alt
		end)
	end

	tasklist.widget_template.update_callback = function(widget, client, index, objects)
		c_callback(widget, client, index, objects)
	end

	return tasklist
end

function bar:set_secondary(s)
	local wibar = awful.wibar {
		position = "bottom",
		ontop = true,
		screen = s,
		height = dpi(45),
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		margins = {
			left = -beautiful.border_width,
			right = -beautiful.border_width,
			top = 0,
			bottom = -beautiful.border_width
		},
		widget = {
			layout = wibox.layout.fixed.horizontal,
			{
				widget = wibox.container.margin,
				margins = dpi(7),
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(7),
					--self.layoutbox(s),
					self.taglist(s),
					self.tasklist(s)
				}
			}
		}
	}

	return wibar
end

function bar:set_primary(s)
	local wibar = awful.wibar {
		position = "bottom",
		ontop = true,
		screen = s,
		height = dpi(45),
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		margins = {
			left = -beautiful.border_width,
			right = -beautiful.border_width,
			top = 0,
			bottom = -beautiful.border_width
		},
		widget = {
			layout = wibox.layout.align.horizontal,
			nil,
			{
				widget = wibox.container.margin,
				margins = dpi(7),
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(7),
					--self.layoutbox(s),
					self.taglist(s),
					self.tasklist(s)
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

	return wibar
end

return bar
