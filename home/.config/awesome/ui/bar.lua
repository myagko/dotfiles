local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")

local Launcher = require("ui.launcher")
local Control_center = require("ui.control_center")

local Bar = {}

local function create_container(widget)
	local box = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		fg = beautiful.foreground,
		{
			widget = wibox.container.margin,
			margins = {
				left = beautiful.bar_module_margins,
				right = beautiful.bar_module_margins
			},
			widget
		}
	}
	return box
end

Bar.launcher = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.accent,
	fg = beautiful.background,
	buttons = {
		awful.button({}, 1, function()
			Launcher:open()
		end)
	},
	{
		widget = wibox.container.margin,
		margins = {
			left = beautiful.bar_module_margins - 1,
			right = beautiful.bar_module_margins - 1
		},
		{
			widget = wibox.widget.textbox,
			align = "center",
			text = ""
		}
	}
}

Bar.time = create_container(wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	spacing = beautiful.bar_module_margins,
	{
		widget = wibox.widget.textclock,
		format = "%b %d, %a"
	},
	helpers:create_sep("v", beautiful.sep_width, { top = beautiful.bar_module_margins/2, bottom = beautiful.bar_module_margins/2 }),
	{
		widget = wibox.widget.textclock,
		format = "%H:%M",
	}
})

Bar.time.buttons = {
	awful.button({}, 1, function()
		Control_center:open("daily")
	end)
}

local tray_rev = wibox.widget {
	widget = wibox.widget.textbox,
	text = "",
}

local tray_w = wibox.widget {
	widget = wibox.container.margin,
	margins = { top = beautiful.bar_module_margins/2, bottom = beautiful.bar_module_margins/2 },
	{
		widget = wibox.widget.systray,
	}
}

local tray_layout = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	spacing = beautiful.bar_module_margins,
	tray_rev
}

Bar.tray = create_container(tray_layout)

local tray_visibility = false

tray_rev:buttons {
	awful.button({}, 1, function()
		tray_visibility = not tray_visibility
		if not tray_visibility then
			tray_layout:insert(2, tray_w)
			tray_rev.text = ""
		else
			tray_layout:remove(2)
			tray_rev.text = ""
		end
	end)
}

Bar.kblayout = create_container(awful.widget.keyboardlayout {})
Bar.kblayout.widget.margins = { left = beautiful.bar_module_margins - 8, right = beautiful.bar_module_margins - 8 }

function Bar:create_taglist(s)
	local taglist_w = awful.widget.taglist {
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = {
			awful.button({ }, 1, function(t)
				t:view_only()
			end)
		},
		layout = {
			spacing = beautiful.taglist_margins,
			layout = wibox.layout.fixed.horizontal
		},
		widget_template = {
			id = "t_container",
			widget = wibox.container.background,
			forced_width = beautiful.taglist_item_size
		}
	}

	local function t_callback(w, t)
		if t.selected then
			w:get_children_by_id("t_container")[1].bg = beautiful.accent
		elseif #t:clients() > 0 then
			w:get_children_by_id("t_container")[1].bg = beautiful.background_urgent
		else
			w:get_children_by_id("t_container")[1].bg = beautiful.background_alt
		end

		for _, c in ipairs(t:clients()) do
			if c.urgent then
				w:get_children_by_id("t_container")[1].bg = beautiful.red
				break
			end
		end
	end

	taglist_w.widget_template.create_callback = function(w, t, i, o)
		t_callback(w, t)
	end
	taglist_w.widget_template.update_callback = function(w, t, i, o)
		t_callback(w, t)
	end

	self.taglist = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		{
			widget = wibox.container.margin,
			margins = {
				left = beautiful.taglist_margins,
				right = beautiful.taglist_margins,
				top = beautiful.taglist_margins - 1,
				bottom = beautiful.taglist_margins - 1
			},
			taglist_w
		}
	}

	return self.taglist
end

function Bar:create_tasklist(s)
	self.tasklist = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = {
			awful.button({ }, 1, function(c)
				c:activate { context = "tasklist", action = "toggle_minimization" }
			end),
			awful.button({ }, 2, function(c)
				c:kill { context = "tasklist", action = "close client" }
			end),
		},
		layout = {
			spacing = beautiful.bar_spacing,
			layout = wibox.layout.fixed.horizontal,
		},
		widget_template = {
			widget = wibox.container.background,
			id = "c_container",
			bg = beautiful.background_alt,
			{
				layout = wibox.layout.align.vertical,
				nil,
				{
					widget = wibox.container.margin,
					margins = {
						left = beautiful.tasklist_margins,
						right = beautiful.tasklist_margins,
						top = beautiful.tasklist_margins/2,
						bottom = beautiful.tasklist_margins/2
					},
					{
						widget = wibox.widget.textbox,
						id = "c_name"
					}
				},
				{
					widget = wibox.container.background,
					id = "c_selection",
					forced_height = beautiful.tasklist_selection_size
				}
			}
		}
	}

	local function c_callback(w, c)
		w:get_children_by_id("c_name")[1].text = c.name
		if c.minimized then
			w:get_children_by_id("c_container")[1].fg = beautiful.foreground_alt
		else
			w:get_children_by_id("c_container")[1].fg = beautiful.foreground
		end
		if c.active then
			w:get_children_by_id("c_selection")[1].bg = beautiful.accent
		else
			w:get_children_by_id("c_selection")[1].bg = beautiful.background_alt
		end
	end

	self.tasklist.widget_template.create_callback = function(w, c, i, o)
		c_callback(w, c)
	end
	self.tasklist.widget_template.update_callback = function(w, c, i, o)
		c_callback(w, c)
	end

	return self.tasklist
end

function Bar:create_main(s)
	local bar_w = wibox.widget {
		layout = wibox.layout.align.horizontal,
		nil,
		{
			widget = wibox.container.margin,
			margins = beautiful.bar_spacing,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = beautiful.bar_spacing + 1,
				self:create_taglist(s),
				self:create_tasklist(s),
			}
		},
		{
			widget = wibox.container.margin,
			margins = {
				top = beautiful.bar_spacing,
				bottom = beautiful.bar_spacing,
				left = 0,
				right = beautiful.bar_spacing
			},
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = beautiful.bar_spacing,
				self.tray,
				self.kblayout,
				self.time,
				self.launcher
			}
		}
	}

	self.wibar = awful.wibar {
		position = "bottom",
		screen = s,
		height = beautiful.bar_height + beautiful.border_width,
		widget = {
			widget = wibox.container.background,
			bg = beautiful.background_urgent,
			{
				widget = wibox.container.margin,
				margins = { top = beautiful.border_width },
				{
					widget = wibox.container.background,
					bg = beautiful.background,
					bar_w
				}
			}
		}
	}
	return self.wibar
end

return Bar
