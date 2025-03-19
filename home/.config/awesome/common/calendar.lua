local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local text_icons = beautiful.text_icons
local dpi = beautiful.xresources.apply_dpi

local calendar = {}

local hebr_format = {
	[1] = 7,
	[2] = 1,
	[3] = 2,
	[4] = 3,
	[5] = 4,
	[6] = 5,
	[7] = 6
}

local function wday_widget(index)
	return wibox.widget {
		widget = wibox.container.background,
		fg = index >= 6 and beautiful.red or beautiful.fg,
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = beautiful.font_h0,
				markup = os.date("%a", os.time({
					year = 1,
					month = 1,
					day = index
				}))
			}
		}
	}
end

local function day_widget(day, is_current, is_another_month)
	local fg_color = beautiful.fg
	local bg_color = beautiful.bg_alt

	if is_current then
		fg_color = beautiful.bg
		bg_color = beautiful.ac
	elseif is_another_month then
		fg_color = beautiful.fg_alt
		bg_color = beautiful.bg_alt
	end

	return wibox.widget {
		widget = wibox.container.background,
		fg = fg_color,
		bg = bg_color,
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				widget = wibox.widget.textbox,
				align = "center",
				markup = day
			}
		}
	}
end

function calendar:set_date(date)
	local wp = self._private
	local days_layout = self:get_children_by_id("days_layout")[1]
	local title_textbox = self:get_children_by_id("title_textbox")[1]
	days_layout:reset()

	wp.date = date
	local curr_date = os.date("*t")
	local firstday = os.date("*t", os.time({
		year = date.year,
		month = date.month,
		day = 1
	}))
	local lastday = os.date("*t", os.time({
		year = date.year,
		month = date.month + 1,
		day = 0
	}))
	local month_count = lastday.day
	local month_start = not wp.sun_start and hebr_format[firstday.wday] or firstday.wday
	local rows = math.max(5, math.min(6, 5 - (36 - (month_start + month_count))))
	local month_prev_lastday = os.date("*t", os.time({
		year = date.year,
		month = date.month,
		day = 0
	})).day
	local month_prev_count = month_start - 1
	local month_next_count = rows*7 - lastday.day - month_prev_count

	title_textbox:set_markup(os.date("%B, %Y", os.time(date)))

	for day = month_prev_lastday - (month_prev_count - 1), month_prev_lastday, 1 do
		days_layout:add(day_widget(day, false, true))
	end

	for day = 1, month_count, 1 do
		local is_current = day == curr_date.day and date.month == curr_date.month and date.year == curr_date.year
		days_layout:add(day_widget(day, is_current, false))
	end

	for day = 1, month_next_count, 1 do
		days_layout:add(day_widget(day, false, true))
	end
end

function calendar:inc(dir)
	local wp = self._private
	local new_calendar_month = wp.date.month + dir
	self:set_date({
		year = wp.date.year,
		month = new_calendar_month,
		day = wp.date.day
	})
end

function calendar:set_current_date()
	self:set_date(os.date("*t"))
end

local function new(args)
	args = args or {}
	local widget

	widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg_alt,
		{
			widget = wibox.container.margin,
			margins = dpi(20),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				{
					layout = wibox.layout.align.horizontal,
					{
						id = "title_background",
						widget = wibox.container.background,
						buttons = {
							awful.button({}, 1, function()
								widget:set_current_date()
							end)
						},
						{
							id = "title_textbox",
							widget = wibox.widget.textbox,
							align = "center"
						}
					},
					nil,
					{
						widget = wibox.layout.fixed.horizontal,
						spacing = dpi(20),
						{
							id = "dec_button",
							widget = wibox.container.background,
							buttons = {
								awful.button({}, 1, function()
									widget:inc(-1)
								end)
							},
							{
								widget = wibox.widget.textbox,
								markup = text_icons.arrow_up
							}
						},
						{
							id = "inc_button",
							widget = wibox.container.background,
							buttons = {
								awful.button({}, 1, function()
									widget:inc(1)
								end)
							},
							{
								widget = wibox.widget.textbox,
								markup = text_icons.arrow_down
							}
						}
					}
				},
				{
					id = "wdays_layout",
					layout = wibox.layout.flex.horizontal
				},
				{
					id = "days_layout",
					layout = wibox.layout.grid,
					forced_num_cols = 7,
					expand = true,
					forced_height = dpi(230)
				}
			}
		}
	}

	gtable.crush(widget, calendar, true)

	local wp = widget._private
	widget._private.sun_start = args.sun_start or false

	local wdays_layout = widget:get_children_by_id("wdays_layout")[1]

	for i = 1, 7 do
		wdays_layout:add(wp.sun_start and wday_widget(hebr_format[i]) or wday_widget(i))
	end

	local title_background = widget:get_children_by_id("title_background")[1]
	local dec_button = widget:get_children_by_id("dec_button")[1]
	local inc_button = widget:get_children_by_id("inc_button")[1]

	local hover_items = {
		title_background,
		dec_button,
		inc_button
	}

	for _, item in ipairs(hover_items) do
		item:connect_signal("mouse::enter", function(w)
			w:set_fg(beautiful.ac)
		end)
		item:connect_signal("mouse::leave", function(w)
			w:set_fg(beautiful.fg)
		end)
		item:connect_signal("button::press", function(w)
			w:set_fg(beautiful.fg)
		end)
	end

	widget:set_current_date()

	return widget
end

return setmetatable(calendar, {
	__call = function(_, ...)
		return new(...)
	end
})
