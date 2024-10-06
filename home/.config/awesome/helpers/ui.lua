local wibox = require("wibox")
local beautiful = require("beautiful")

local ui = {}

function ui.set_markup(text, args)
	args = args or {}
	local font = args.font and "font='" .. args.font .. "' " or ""
	local size = args.size and "size='" .. args.size .. "' " or ""
	local style = args.style and "style='" .. args.style .. "' " or ""
	local weight = args.weight and "weight='" .. args.weight .. "' " or ""
	local stretch = args.stretch and "stretch='" .. args.stretch .. "' " or ""
	local font_scale = args.font_scale and "font_scale='" .. args.font_scale .. "' " or ""
	local underline = args.underline and "underline='" .. args.underline .. "' " or ""
	local overline = args.overline and "overline='" .. args.overline .. "' " or ""
	local strikethrough = args.strikethrough and "strikethrough='" .. args.strikethrough .. "' " or ""
	local alpha = args.alpha and "alpha='" .. args.alpha .. "' " or ""
	local fg = args.fg and "foreground='" .. args.fg .. "' " or ""
	local bg = args.bg and "background='" .. args.bg .. "'" or ""
	return "<span " .. font .. size .. style .. weight .. stretch .. font_scale ..
		underline .. overline .. strikethrough .. alpha .. fg .. bg .. ">" .. text .. "</span>"
end

function ui.create_sep(args)
	setmetatable(args, {
		__index = {
			orientation = "h",
			size = 1,
			margins = 0,
			color = beautiful.background_urgent
		}
	})

	local sep = wibox.widget {
		widget = wibox.container.margin,
		margins = args.margins,
		{
			id = "sep",
			widget = wibox.container.background,
			bg = args.color
		}
	}

	if args.orientation == "h" then
		sep:get_children_by_id("sep")[1].forced_height = args.size
	elseif args.orientation == "v" then
		sep:get_children_by_id("sep")[1].forced_width = args.size
	end

	function sep:set_color(color)
		self:get_children_by_id("sep")[1].bg = color
	end

	return sep
end

function ui.create_hover_button(args)
	setmetatable(args, {
		__index = {
			markup = "",
			font = beautiful.font,
			align = "center",
			fg_normal = beautiful.foreground,
			bg_normal = beautiful.background_alt,
			fg_hover = beautiful.background,
			bg_hover = beautiful.accent,
			border_width = 0,
			border_color = beautiful.border_color,
			margins = 0,
			forced_width = nil,
			forced_height = nil,
			buttons = nil
		}
	})

	local button = wibox.widget {
		widget = wibox.container.background,
		buttons = args.buttons,
		forced_width = args.forced_width,
		forced_height = args.forced_height,
		border_width = args.border_width,
		border_color = args.border_color,
		bg_hover = args.bg_hover,
		fg_hover = args.fg_hover,
		bg_normal = args.bg_normal,
		fg_normal = args.fg_normal,
		bg = args.bg_normal,
		fg = args.fg_normal,
		{
			widget = wibox.container.margin,
			margins = args.margins,
			{
				id = "text_comp",
				widget = wibox.widget.textbox,
				font = args.font,
				align = args.align,
				markup = args.markup
			}
		}
	}

	button:connect_signal("mouse::enter", function(w)
		w.bg = w.bg_hover
		w.fg = w.fg_hover
	end)

	button:connect_signal("mouse::leave", function(w)
		w.bg = w.bg_normal
		w.fg = w.fg_normal
	end)

	function button:set_text(markup)
		self:get_children_by_id("text_comp")[1].markup = markup
	end

	return button
end

return ui
