local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Helpers = {}

function Helpers:remote_watch(command, interval, output_file, callback)
	local run_the_thing = function()
		awful.spawn.easy_async_with_shell(command .. " | tee " .. output_file, function(out) callback(out) end)
	end

	local timer
	timer = gears.timer {
		timeout = interval,
		call_now = true,
		autostart = true,
		single_shot = false,
		callback = function()
			awful.spawn.easy_async_with_shell("date -r " .. output_file .. " +%s", function(last_update, _, _, exitcode)
				if exitcode == 1 then
					run_the_thing()
					return
				end

				local diff = os.time() - tonumber(last_update)
				if diff >= interval then
					run_the_thing()
				else
					awful.spawn.easy_async_with_shell("cat " .. output_file, function(out) callback(out) end)
					timer:stop()
					gears.timer.start_new(interval - diff, function()
						run_the_thing()
						timer:again()
					end)
				end
			end)
		end
	}
end

function Helpers:colorize_markup(text, fg)
	if not fg then fg = beautiful.foreground end
	return "<span foreground='" .. fg .. "'>" .. text .. "</span>"
end

function Helpers:inc_fontsize(inc, font)
	if not font then font = beautiful.font_name end
	return font .. " " .. tostring(beautiful.font_size + inc)
end

function Helpers:recolor_image(image, color)
	if not image then return end
	if not color then color = beautiful.foreground end
	awful.spawn.with_shell("convert " .. image .. " -alpha extract -background '" .. color .. "' -alpha shape -define png:color-type=6 " .. image)
end

function Helpers:create_sep(orientation, size, margins, color)
	local sep = wibox.widget {
		widget = wibox.container.margin,
		margins = margins or 0,
		{
			widget = wibox.container.background,
			bg = color or beautiful.background_urgent,
		}
	}

	if orientation == "h" then
		sep.widget.forced_height = size
	elseif orientation == "v" then
		sep.widget.forced_width = size
	end

	return sep
end

return Helpers
