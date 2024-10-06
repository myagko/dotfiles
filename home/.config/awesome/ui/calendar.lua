local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local calendar = {}
local instance = nil

local hebr_format = {
	[1] = 7,
	[2] = 1,
	[3] = 2,
	[4] = 3,
	[5] = 4,
	[6] = 5,
	[7] = 6
}

local function create_wday_widget(wday, color)
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

local function create_day_widget(day, is_current, is_another_month)
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

function calendar:set(date)
	calendar.day_layout:reset()
	self.date = date

	local curr_date = os.date("*t")
	local firstday = os.date("*t", os.time({ year = date.year, month = date.month, day = 1 }))
	local lastday = os.date("*t", os.time({ year = date.year, month = date.month + 1, day = 0 }))

	local month_count = lastday.day
	local month_start = not self.sun_start and hebr_format[firstday.wday] or firstday.wday
	local rows = math.max(5, math.min(6, 5 - (36 - (month_start + month_count))))

	local month_prev_lastday = os.date("*t", os.time({ year = date.year, month = date.month, day = 0 })).day
	local month_prev_count = month_start - 1
	local month_next_count = rows*7 - lastday.day - month_prev_count

	self.top_widget:get_children_by_id("title")[1].markup = os.date("%B, %Y", os.time(date))

	for day = month_prev_lastday - (month_prev_count - 1), month_prev_lastday, 1 do
		self.day_layout:add(create_day_widget(day, false, true))
	end

	for day = 1, month_count, 1 do
		local is_current = day == curr_date.day and date.month == curr_date.month and date.year == curr_date.year
		self.day_layout:add(create_day_widget(day, is_current, false))
	end

	for day = 1, month_next_count, 1 do
		self.day_layout:add(create_day_widget(day, false, true))
	end
end

function calendar:inc(dir)
	local new_calendar_month = self.date.month + dir
	self:set({ year = self.date.year, month = new_calendar_month, day = self.date.day })
end

local function new()
	local ret = calendar

	ret.sun_start = false

	ret.day_layout = wibox.widget {
		layout = wibox.layout.grid,
		forced_num_cols = 7,
		expand = true,
		forced_height = dpi(230)
	}

	ret.wday_layout = wibox.widget {
		layout = wibox.layout.flex.horizontal
	}

	for i = 1, 7 do
		if ret.sun_start then
			i = i - 1
			if i > 0 and i < 6 then
				ret.wday_layout:add(create_wday_widget(os.date("%a", os.time({year = 1, month = 1, day = i}))))
			else
				ret.wday_layout:add(create_wday_widget(os.date("%a", os.time({year = 1, month = 1, day = i})), beautiful.red))
			end
		else
			if i < 6 then
				ret.wday_layout:add(create_wday_widget(os.date("%a", os.time({year = 1, month = 1, day = i}))))
			else
				ret.wday_layout:add(create_wday_widget(os.date("%a", os.time({year = 1, month = 1, day = i})), beautiful.red))
			end
		end
	end

	ret.top_widget = wibox.widget {
		layout = wibox.layout.align.horizontal,
		{
			widget = wibox.container.background,
			buttons = {
				awful.button({}, 1, function()
					ret:set(os.date("*t"))
				end)
			},
			{
				id = "title",
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
						ret:inc(-1)
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
						ret:inc(1)
					end)
				},
				{
					widget = wibox.widget.textbox,
					markup = text_icons.arrow_right
				}
			}
		}
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.background_alt,
		{
			widget = wibox.container.margin,
			margins = dpi(20),
			{
				layout = wibox.layout.fixed.vertical,
				spacing = dpi(5),
				ret.top_widget,
				ret.wday_layout,
				ret.day_layout
			}
		}
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
