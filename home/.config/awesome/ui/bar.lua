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
			margins = { left = 8, right = 8 },
			widget
		}
	}
	return box
end

Bar.launcher = wibox.widget {
	widget = wibox.container.background,
	buttons = {
		awful.button({}, 1, function()
			Launcher:open()
		end)
	},
	{
		widget = wibox.widget.imagebox,
		scaling_quality = "nearest",
		image = beautiful.theme_assets.awesome_icon(20, beautiful.accent, beautiful.background)
	}
}

Bar.time = create_container(wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	spacing = 10,
	{
		widget = wibox.widget.textclock,
		format = "%b %d, %a"
	},
	helpers:create_sep("v", beautiful.sep_width, { top = 4, bottom = 4 }),
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

local ram_w = wibox.widget {
	widget = wibox.widget.textbox
}

local cpu_w = wibox.widget {
	widget = wibox.widget.textbox
}

awesome.connect_signal("stats::ram", function (value)
	ram_w.text = " " .. value .. "%"
end)

awesome.connect_signal("stats::cpu", function (value)
	cpu_w.text = " " .. value .. "%"
end)

Bar.stats = create_container(wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	spacing = 10,
	cpu_w,
	helpers:create_sep("v", beautiful.sep_width, { bottom = 4, top = 4 }),
	ram_w
})

local tray_rev = wibox.widget {
	widget = wibox.widget.textbox,
	text = "",
}

local tray_w = wibox.widget {
	widget = wibox.container.margin,
	margins = { top = 4, bottom = 4 },
	{
		widget = wibox.widget.systray,
	}
}

local tray_layout = wibox.widget {
	layout = wibox.layout.fixed.horizontal,
	spacing = 8,
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
Bar.kblayout.widget.margins = { left = 0, right = 0 }

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
			spacing = 9,
			layout = wibox.layout.fixed.horizontal
		},
		widget_template = {
			id = "t_container",
			widget = wibox.container.background,
			forced_width = 15
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
			margins = { left = 9, right = 9, top = 8, bottom = 8 },
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
			spacing = 7,
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
					margins = { left = 8, right = 8, top = 4, bottom = 4 },
					{
						widget = wibox.widget.textbox,
						id = "c_name"
					}
				},
				{
					widget = wibox.container.background,
					id = "c_selection",
					forced_height = 2
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
			margins = 7,
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 8,
				self:create_taglist(s),
				self:create_tasklist(s),
			}
		},
		{
			widget = wibox.container.margin,
			margins = { top = 7, bottom = 7, left = 0, right = 7 },
			{
				layout = wibox.layout.fixed.horizontal,
				spacing = 7,
				self.tray,
				self.kblayout,
				self.stats,
				self.time,
				self.launcher
			}
		}
	}

	self.wibar = awful.wibar {
		position = "bottom",
		screen = s,
		height = 45 + beautiful.border_width,
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
