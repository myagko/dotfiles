local awful = require("awful")
local wibox = require("wibox")
local gtable = require("gears.table")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

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

local function wday_w(wday, color)
	local fg_color = color or beautiful.foreground
	return wibox.widget {
		widget = wibox.container.background,
		fg = fg_color,
		{
			widget = wibox.container.margin,
			margins = dpi(10),
			{
				widget = wibox.widget.textbox,
				align = "center",
				markup = wday
			}
		}
	}
end

local function day_w(day, is_current, is_another_month)
	local fg_color = beautiful.foreground
	local bg_color = beautiful.background_alt

	if is_current then
		fg_color = beautiful.background
		bg_color = beautiful.accent
	elseif is_another_month then
		fg_color = beautiful.foreground_alt
		bg_color = beautiful.background_alt
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
	self:get_children_by_id("days")[1]:reset()
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
	self:get_children_by_id("month_year")[1].markup = os.date("%B, %Y", os.time(date))

	for day = month_prev_lastday - (month_prev_count - 1), month_prev_lastday, 1 do
		self:get_children_by_id("days")[1]:add(day_w(day, false, true))
	end

	for day = 1, month_count, 1 do
		local is_current = day == curr_date.day and date.month == curr_date.month and date.year == curr_date.year
		self:get_children_by_id("days")[1]:add(day_w(day, is_current, false))
	end

	for day = 1, month_next_count, 1 do
		self:get_children_by_id("days")[1]:add(day_w(day, false, true))
	end
end

function calendar:inc(dir)
	local wp = self._private
	local new_calendar_month = wp.date.month + dir
	self:set_date({
		year = wp.date.year,
		month = new_calendar_month,
		day = wp.date.day })
end

function calendar:set_current_date()
	self:set_date(os.date("*t"))
end

local function new(args)
	args = args or {}
	local widget

	widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		{
			widget = wibox.container.margin,
			margins = dpi(20),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				{
					layout = wibox.layout.align.horizontal,
					{
						widget = wibox.container.background,
						buttons = {
							awful.button({}, 1, function()
								widget:set_current_date()
							end)
						},
						{
							id = "month_year",
							widget = wibox.widget.textbox,
							align = "center"
						}
					},
					nil,
					{
						widget = wibox.layout.fixed.horizontal,
						spacing = dpi(20),
						{
							widget = wibox.container.background,
							buttons = {
								awful.button({}, 1, function()
									widget:inc(-1)
								end)
							},
							{
								widget = wibox.widget.textbox,
								markup = text_icons.arrow_left
							}
						},
						{
							widget = wibox.container.background,
							buttons = {
								awful.button({}, 1, function()
									widget:inc(1)
								end)
							},
							{
								widget = wibox.widget.textbox,
								markup = text_icons.arrow_right
							}
						}
					}
				},
				{
					id = "wdays",
					layout = wibox.layout.flex.horizontal
				},
				{
					id = "days",
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

	local wdays = widget:get_children_by_id("wdays")[1]
	if wp.sun_start then
		wdays:add(wday_w("Su", beautiful.red))
		wdays:add(wday_w("Mo"))
		wdays:add(wday_w("Tu"))
		wdays:add(wday_w("We"))
		wdays:add(wday_w("Th"))
		wdays:add(wday_w("Fr"))
		wdays:add(wday_w("Sa", beautiful.red))
	else
		wdays:add(wday_w("Mo"))
		wdays:add(wday_w("Tu"))
		wdays:add(wday_w("We"))
		wdays:add(wday_w("Th"))
		wdays:add(wday_w("Fr"))
		wdays:add(wday_w("Sa", beautiful.red))
		wdays:add(wday_w("Su", beautiful.red))
	end

	widget:set_current_date()

	return widget
end

return setmetatable(calendar, {
	__call = function(_, ...)
		return new(...)
	end
})
