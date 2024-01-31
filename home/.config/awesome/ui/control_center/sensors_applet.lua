local wibox = require("wibox")
local beautiful = require("beautiful")

local Sensors = {}

Sensors.textbox = wibox.widget {
	widget = wibox.widget.textbox,
	justify = true
}

Sensors.main_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background_alt,
	{
		widget = wibox.container.margin,
		margins = 10,
		Sensors.textbox
	}
}

awesome.connect_signal("stats::sensors", function(stdout)
	Sensors.textbox.text = stdout
end)

return Sensors
