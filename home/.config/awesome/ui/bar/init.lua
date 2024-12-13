local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons
local launcher = require("ui.launcher")
local day_info = require("ui.day_info_panel")

local bar = {}

local function launcher_button()
	local widget = wibox.widget {
		widget = wibox.container.background,
		forced_width = dpi(31),
		bg = beautiful.accent,
		fg = beautiful.background,
		buttons = {
			awful.button({}, 1, function()
				launcher:toggle()
			end)
		},
		{
			widget = wibox.widget.textbox,
			align = "center",
			text = text_icons.apps
		}
	}

	return widget
end

local function time()
	local sep = widgets.separator {
		dir = "v",
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

local function tray()
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

local function kblayout()
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

local function layoutbox(s)
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

local function taglist(s)
	local widget = awful.widget.taglist {
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
			id = "t_selection",
			widget = wibox.container.background,
			{
				widget = wibox.container.margin,
				margins = { left = dpi(8), right = dpi(8) },
				{
					id = "t_text",
					widget = wibox.widget.textbox,
					align = "center"
				}
			}
		}
	}

	local function t_callback(tw, t)
		local t_selection = tw:get_children_by_id("t_selection")[1]
		local t_text = tw:get_children_by_id("t_text")[1]

		t_text.markup = t.index

		if t.selected then
			t_selection.bg = beautiful.accent
			t_selection.fg = beautiful.background
		elseif #t:clients() > 0 then
			t_selection.bg = beautiful.background_alt
			t_selection.fg = beautiful.foreground
		else
			t_selection.bg = beautiful.background_alt
			t_selection.fg = beautiful.foreground_alt
		end

		for _, c in ipairs(t:clients()) do
			if c.urgent then
				t_selection.fg = beautiful.red
				break
			end
		end
	end

	widget.widget_template.create_callback = function(tw, t)
		t_callback(tw, t)
		local t_selection = tw:get_children_by_id("t_selection")[1]

		tw:connect_signal("mouse::enter", function()
			if not t.selected then
				t_selection.bg = beautiful.background_urgent
			end
		end)

		tw:connect_signal("mouse::leave", function()
			if not t.selected then
				t_selection.bg = beautiful.background_alt
			end
		end)
	end

	widget.widget_template.update_callback = function(tw, t)
		t_callback(tw, t)
	end

	return widget
end

local function tasklist(s)
	local tasklist_w = awful.widget.tasklist {
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
							id = "c_text",
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

	local function c_callback(tw, c)
		local c_container = tw:get_children_by_id("c_container")[1]
		local c_selection = tw:get_children_by_id("c_selection")[1]
		local c_text = tw:get_children_by_id("c_text")[1]

		c_text.markup = c.class or "no class"
		c_container.bg = beautiful.background_alt

		if c.minimized then
			c_container.fg = beautiful.foreground_alt
		else
			c_container.fg = beautiful.foreground
		end

		if c.active then
			c_selection.forced_height = dpi(2)
		else
			c_selection.forced_height = 0
		end
	end

	tasklist_w.widget_template.create_callback = function(tw, c)
		c_callback(tw, c)

		tw:connect_signal("mouse::enter", function(w)
			w.bg = beautiful.background_urgent
		end)

		tw:connect_signal("mouse::leave", function(w)
			w.bg = beautiful.background_alt
		end)
	end

	tasklist_w.widget_template.update_callback = function(tw, c)
		c_callback(tw, c)
	end

	return tasklist_w
end

function bar.set_secondary(s)
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
					layoutbox(s),
					taglist(s),
					tasklist(s)
				}
			}
		}
	}

	return wibar
end

function bar.set_primary(s)
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
					layoutbox(s),
					taglist(s),
					tasklist(s)
				}
			},
			{
				widget = wibox.container.margin,
				margins = { top = dpi(7), bottom = dpi(7), left = 0, right = dpi(7) },
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(7),
					tray(),
					kblayout(),
					time(),
					launcher_button()
				}
			}
		}
	}

	return wibar
end

return bar
