local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("widgets")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi
local modkey = "Mod4"

local launcher = require("ui.launcher")
local control_panel = require("ui.control_panel")
local day_info_panel = require("ui.day_info_panel")
local menu = require("ui.menu")

local bar = {}

local function launcher_button()
	return widgets.hover_button {
		buttons = {
			awful.button({}, 1, function()
				launcher:toggle()
			end)
		},
		forced_width = dpi(31),
		bg_normal = beautiful.bg_alt,
		bg_hover = beautiful.bg_urg,
		fg_normal = beautiful.fg,
		fg_hover = beautiful.fg,
		markup = text_icons.menu,
	}
end

local function control_panel_button()
	return widgets.hover_button {
		buttons = {
			awful.button({}, 1, function()
				control_panel:toggle()
			end)
		},
		forced_width = dpi(31),
		bg_normal = beautiful.bg_alt,
		bg_hover = beautiful.bg_urg,
		fg_normal = beautiful.fg,
		fg_hover = beautiful.fg,
		markup = text_icons.sliders,
	}
end

local function time()
	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		buttons = {
			awful.button({}, 1, function()
				day_info_panel:toggle()
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
				{
					id = "separator",
					widget = widgets.separator {
						size = beautiful.sep_width,
						margins = { top = dpi(5), bottom = dpi(5) }
					}
				},
				{
					widget = wibox.widget.textclock,
					format = "%H:%M"
				}
			}
		}
	}

	widget:connect_signal("mouse::enter", function(w)
		w:set_bg(beautiful.bg_urg)
		w:get_children_by_id("separator")[1]:set_color(beautiful.fg_alt)
	end)

	widget:connect_signal("mouse::leave", function(w)
		w:set_bg(beautiful.bg_alt)
		w:get_children_by_id("separator")[1]:set_color(beautiful.bg_urg)
	end)

	return widget
end

local function tray()
	local visibility = false

	local systray = wibox.widget {
		widget = wibox.container.margin,
		margins = { top = dpi(4), bottom = dpi(4) },
		{
			widget = wibox.widget.systray
		}
	}

	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		{
			widget = wibox.container.margin,
			margins = { left = dpi(8), right = dpi(8) },
			{
				id = "items_layout",
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(8),
				{
					id = "revealer",
					widget = wibox.widget.textbox,
					markup = text_icons.arrow_left
				}
			}
		}
	}

	local items_layout = widget:get_children_by_id("items_layout")[1]
	local revealer = widget:get_children_by_id("revealer")[1]

	revealer:buttons {
		awful.button({}, 1, function()
			if not visibility then
				visibility = true
				items_layout:insert(2, systray)
				revealer:set_markup(text_icons.arrow_right)
			else
				visibility = false
				items_layout:remove(2)
				revealer:set_markup(text_icons.arrow_left)
			end
		end)
	}

	widget:connect_signal("mouse::enter", function(w)
		beautiful.bg_systray = beautiful.bg_urg
		w:set_bg(beautiful.bg_urg)
	end)

	widget:connect_signal("mouse::leave", function(w)
		beautiful.bg_systray = beautiful.bg_alt
		w:set_bg(beautiful.bg_alt)
	end)

	return widget
end

local function kblayout()
	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		{
			widget = awful.widget.keyboardlayout {}
		}
	}

	widget:connect_signal("mouse::enter", function(w)
		w:set_bg(beautiful.bg_urg)
	end)

	widget:connect_signal("mouse::leave", function(w)
		w:set_bg(beautiful.bg_alt)
	end)

	return widget
end

local function layoutbox(s)
	local widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
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
		w:set_bg(beautiful.bg_urg)
	end)

	widget:connect_signal("mouse::leave", function(w)
		w:set_bg(beautiful.bg_alt)
	end)

	return widget
end

local function taglist(s)
	local taglist_widget = awful.widget.taglist {
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = {
			awful.button({}, 1, function(t)
				t:view_only()
			end),
			awful.button({}, 3, function(t)
				awful.tag.viewtoggle(t)
			end),
			awful.button({}, 4, function(t)
				awful.tag.viewprev(t.screen)
			end),
			awful.button({}, 5, function(t)
				awful.tag.viewnext(t.screen)
			end),
			awful.button({ modkey }, 1, function(t)
				if client.focus then
					client.focus:move_to_tag(t)
				end
			end),
            awful.button({ modkey }, 3, function(t)
				if client.focus then
					client.focus:toggle_tag(t)
				end
			end),
		},
		layout = {
			layout = wibox.layout.fixed.horizontal
		},
		widget_template = {
			id = "t_selection",
			widget = wibox.container.background,
			{
				widget = wibox.container.margin,
				margins = { left = dpi(9), right = dpi(9) },
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
			t_selection:set_bg(beautiful.ac)
			t_selection:set_fg(beautiful.bg)
		elseif #t:clients() > 0 then
			t_selection:set_bg(beautiful.bg_alt)
			t_selection:set_fg(beautiful.fg)
		else
			t_selection:set_bg(beautiful.bg_alt)
			t_selection:set_fg(beautiful.fg_alt)
		end

		for _, c in ipairs(t:clients()) do
			if c.urgent then
				t_selection:set_fg(beautiful.red)
				break
			end
		end
	end

	taglist_widget.widget_template.create_callback = function(tw, t)
		t_callback(tw, t)
		local t_selection = tw:get_children_by_id("t_selection")[1]

		tw:connect_signal("mouse::enter", function()
			if not t.selected then
				t_selection:set_bg(beautiful.bg_urg)
			end
		end)

		tw:connect_signal("mouse::leave", function()
			if not t.selected then
				t_selection:set_bg(beautiful.bg_alt)
			end
		end)
	end

	taglist_widget.widget_template.update_callback = function(tw, t)
		t_callback(tw, t)
	end

	return wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		{
			widget = taglist_widget
		}
	}
end

local function tasklist(s)
	local tasklist_widget = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = {
			awful.button({ }, 1, function(c)
				c:activate { context = "tasklist", action = "toggle_minimization" }
				menu:hide()
			end),
			awful.button({ }, 3, function(c)
				menu:toggle_client_menu(c)
			end)
		},
		layout = {
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(5),
		},
		widget_template = {
			id = "c_container",
			widget = wibox.container.background,
			{
				layout = wibox.layout.stack,
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
					layout = wibox.layout.align.vertical,
					nil,
					nil,
					{
						widget = wibox.container.margin,
						margins = { left = dpi(10), right = dpi(10) },
						{
							id = "c_pointer",
							widget = wibox.container.background,
							bg = beautiful.ac
						}
					}
				}
			}
		}
	}

	local function c_callback(tw, c)
		local c_container = tw:get_children_by_id("c_container")[1]
		local c_pointer = tw:get_children_by_id("c_pointer")[1]
		local c_text = tw:get_children_by_id("c_text")[1]

		c_text:set_markup(c.class or "untitled")
		c_container:set_bg(beautiful.bg_alt)

		if c.minimized then
			c_container:set_fg(beautiful.fg_alt)
		else
			c_container:set_fg(beautiful.fg)
		end

		if c.active then
			c_pointer:set_forced_height(dpi(3))
		else
			c_pointer:set_forced_height(0)
		end
	end

	tasklist_widget.widget_template.create_callback = function(tw, c)
		c_callback(tw, c)

		tw:connect_signal("mouse::enter", function(w)
			w:set_bg(beautiful.bg_urg)
		end)

		tw:connect_signal("mouse::leave", function(w)
			w:set_bg(beautiful.bg_alt)
		end)
	end

	tasklist_widget.widget_template.update_callback = function(tw, c)
		c_callback(tw, c)
	end

	return tasklist_widget
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
			left = -beautiful.border_width, right = -beautiful.border_width,
			top = 0, bottom = -beautiful.border_width
		},
		widget = {
			layout = wibox.layout.fixed.horizontal,
			{
				widget = wibox.container.margin,
				margins = dpi(7),
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(5),
					--layoutbox(s),
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
			left = -beautiful.border_width, right = -beautiful.border_width,
			top = 0, bottom = -beautiful.border_width
		},
		widget = {
			layout = wibox.layout.align.horizontal,
			nil,
			{
				widget = wibox.container.margin,
				margins = dpi(7),
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(5),
					launcher_button(),
					--layoutbox(s),
					taglist(s),
					tasklist(s)
				}
			},
			{
				widget = wibox.container.margin,
				margins = {
					top = dpi(7), bottom = dpi(7),
					left = 0, right = dpi(7)
				},
				{
					layout = wibox.layout.fixed.horizontal,
					spacing = dpi(5),
					tray(),
					kblayout(),
					time(),
					control_panel_button()
				}
			}
		}
	}

	return wibar
end

return bar
