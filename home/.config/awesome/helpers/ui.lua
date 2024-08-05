local wibox = require("wibox")
local beautiful = require("beautiful")

local ui = {}

function ui.colorize_markup(text, fg)
	fg = fg or beautiful.foreground
	return "<span foreground='" .. fg .. "'>" .. text .. "</span>"
end

function ui.font(size, font)
	font = font or beautiful.font_name
	return font .. " " .. tostring(size)
end

function ui.create_sep(args)
	local props = {
		orientation = "h",
		size = 1,
		margins = 0,
		color = beautiful.background_urgent
	}
	setmetatable(args, { __index = props })

	local sep = wibox.widget {
		widget = wibox.container.margin,
		margins = args.margins,
		{
			widget = wibox.container.background,
			bg = args.color
		}
	}

	if args.orientation == "h" then
		sep.widget.forced_height = args.size
	elseif args.orientation == "v" then
		sep.widget.forced_width = args.size
	end

	return sep
end

function ui.create_hover_button(args)
	local props = {
		text = "",
		font = beautiful.font,
		align = "center",
		fg = beautiful.foreground,
		bg = beautiful.background_alt,
		fg_hover = beautiful.background,
		bg_hover = beautiful.accent,
		border_width = 0,
		border_color = beautiful.border_color,
		margins = 0,
		forced_width = nil,
		forced_height = nil,
		buttons = nil
	}
	setmetatable(args, { __index = props })

	local button = wibox.widget {
		id = args.id,
		widget = wibox.container.background,
		buttons = args.buttons,
		forced_width = args.forced_width,
		forced_height = args.forced_height,
		border_width = args.border_width,
		border_color = args.border_color,
		bg = args.bg,
		fg = args.fg,
		{
			widget = wibox.container.margin,
			margins = args.margins,
			{
				id = "text_comp",
				widget = wibox.widget.textbox,
				font = args.font,
				align = args.align,
				text = args.text
			}
		}
	}

	button:connect_signal("mouse::enter", function()
		button.bg = args.bg_hover
		button.fg = args.fg_hover
	end)

	button:connect_signal("mouse::leave", function()
		button.bg = args.bg
		button.fg = args.fg
	end)

	function button:set_text(text)
		self:get_children_by_id("text_comp")[1].text = text
	end

	return button
end

return ui
