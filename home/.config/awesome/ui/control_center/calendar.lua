local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Calendar = {}

local eu_wday_format = {
	[1] = 7,
	[2] = 1,
	[3] = 2,
	[4] = 3,
	[5] = 4,
	[6] = 5,
	[7] = 6
}

local function create_month_widget(month, color)
	local fg_color = color or beautiful.foreground
	return wibox.widget {
		widget = wibox.container.background,
		fg = fg_color,
		{
			widget = wibox.container.margin,
			margins = 10,
			{
				widget = wibox.widget.textbox,
				text = month
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
			margins = 10,
			{
				widget = wibox.widget.textbox,
				text = day
			}
		}
	}
end

Calendar.m_layout = wibox.widget {
	layout = wibox.layout.grid,
	forced_num_cols = 7,
	expand = true,
	forced_height = 280
}

Calendar.monthtitle = wibox.widget {
	widget = wibox.widget.textbox,
	align = "center"
}

Calendar.top_widget = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{
		widget = wibox.container.background,
		buttons = {
			awful.button({}, 1, function()
				Calendar:inc(-1)
			end)
		},
		{
			widget = wibox.widget.textbox,
			text = ""
		}
	},
	{
		widget = wibox.container.background,
		buttons = {
			awful.button({}, 1, function()
				Calendar:set(os.date("*t"))
			end)
		},
		Calendar.monthtitle
	},
	{
		widget = wibox.container.background,
		buttons = {
			awful.button({}, 1, function()
				Calendar:inc(1)
			end)
		},
		{
			widget = wibox.widget.textbox,
			text = ""
		}
	}
}

function Calendar:set(date)
	Calendar.m_layout:reset()
	self.date = date
	local curr_date = os.date("*t")

	local firstday = os.date("*t", os.time({ year = date.year, month = date.month, day = 1 }))
	local lastday = os.date("*t", os.time({ year = date.year, month = date.month + 1, day = 0 }))

	local month_count = lastday.day
	local month_start = eu_wday_format[firstday.wday]

	local rows = math.max(5, math.min(6, 5 - (36 - (month_start + month_count))))

	local month_prev_lastday = os.date("*t", os.time({ year = date.year, month = date.month, day = 0 })).day

	local month_prev_count = eu_wday_format[firstday.wday] - 1
	local month_next_count = rows*7 - lastday.day - month_prev_count

	self.monthtitle.text = os.date("%B, %Y", os.time(date))

	self.m_layout:add(
		create_month_widget("Mon"),
		create_month_widget("Tue"),
		create_month_widget("Wed"),
		create_month_widget("Thu"),
		create_month_widget("Fri"),
		create_month_widget("Sat", beautiful.red),
		create_month_widget("Sun", beautiful.red)
	)

	for day = month_prev_lastday - (month_prev_count - 1), month_prev_lastday, 1 do
		self.m_layout:add(create_day_widget(day, false, true))
	end

	for day = 1, month_count, 1 do
		local is_current = day == curr_date.day and date.month == curr_date.month and date.year == curr_date.year
		self.m_layout:add(create_day_widget(day, is_current, false))
	end

	for day = 1, month_next_count, 1 do
		self.m_layout:add(create_day_widget(day, false, true))
	end
end

function Calendar:inc(dir)
	local new_calendar_month = self.date.month + dir
	self:set({ year = self.date.year, month = new_calendar_month, day = self.date.day })
end

Calendar.main_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	{
		widget = wibox.container.margin,
		margins = 20,
		{
			layout = wibox.layout.fixed.vertical,
			spacing = 10,
			Calendar.top_widget,
			Calendar.m_layout
		}
	}
}

return Calendar
