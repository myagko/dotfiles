local awful = require("awful")
local inspect = require("external.inspect")

local helpers = {}

function helpers.create_markup(text, args)
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

function helpers.spawn_once(cmd_arr)
	for _, cmd in ipairs(cmd_arr) do
		local findme = cmd
		local firstspace = cmd:find(" ")
		if firstspace then
			findme = cmd:sub(0, firstspace - 1)
		end
		awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
	end
end

function helpers.to_direction(deg)
	if deg == nil then
		return "Unknown dir"
	end

	local directions = {
		"N", "NNE", "NE", "ENE",
		"E", "ESE", "SE", "SSE",
		"S", "SSW", "SW", "WSW",
		"W", "WNW", "NW", "NNW",
		"N"
	}
	return directions[math.floor((deg%360)/22.5) + 1]
end

function helpers.string_trim(string)
	return string:gsub("^%s*(.-)%s*$", "%1")
end

function helpers.lua_escape(string)
	return string:gsub("[%[%]%(%)%.%-%+%?%*%%]", "%%%1")
end

function helpers.has_common_values(t1, t2)
	local common = {}
	for _, v1 in pairs(t1) do
		for _, v2 in pairs(t2) do
			if v1 == v2 then
				table.insert(common, v1)
			end
		end
	end
	return #common > 0 and common or nil
end

function helpers.table_to_file(file, table, tablename)
	tablename = tablename or "M"
	local inspected = assert(inspect(table, { indent = "\t" }))
	local wfile = assert(io.open(file, "w"))
	wfile:write("local " .. tablename .. " = " .. inspected .. "\n\nreturn " .. tablename)
	wfile:close()
end

function helpers.remove_nonindex_value(tbl, val)
	for i, v in ipairs(tbl) do
		if v == val then
			table.remove(tbl, i)
		end
	end
end

return helpers
