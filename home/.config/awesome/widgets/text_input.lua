local utf8 = require("lua-utf8")
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local Gdk = lgi.require("Gdk", "3.0")
local awful = require("awful")
local gtable = require("gears.table")
local gstring = require("gears.string")
local gcolor = require("gears.color")

local text_input = {}

local function create_markup(args)
	local text = args.text or ""
	local cursor_pos = args.cursor_pos or 1
	local selectall = args.selectall or false
	local prompt = args.prompt or ""
	local placeholder = args.placeholder or ""
	local obscure = args.obscure or false
	local obscure_char = args.obscure_char or "*"
	local highlighter = args.highlighter or nil
	local cursor_char, spacer, text_start, text_end, markup

	if obscure and text ~= "" then
		text = utf8.gsub(text, "(.)", obscure_char)
	end

	if text == "" and placeholder ~= "" then
		spacer = ""
		cursor_char = gstring.xml_escape(utf8.sub(placeholder, cursor_pos, cursor_pos))
		text_start = ""
		text_end = gstring.xml_escape(utf8.sub(placeholder, 2))
	elseif selectall then
		if text == "" then
			cursor_char = " "
		else
			cursor_char = gstring.xml_escape(text)
		end
		spacer = " "
		text_start = ""
		text_end = ""
	elseif utf8.len(text) < cursor_pos then
		cursor_char = " "
		spacer = ""
		text_start = gstring.xml_escape(text)
		text_end = ""
	else
		cursor_char = gstring.xml_escape(utf8.sub(text, cursor_pos, cursor_pos))
		spacer = " "
		text_start = gstring.xml_escape(utf8.sub(text, 1, cursor_pos - 1))
		text_end = gstring.xml_escape(utf8.sub(text, cursor_pos + 1))
	end

	local cursor_bg = gcolor.ensure_pango_color(args.cursor_bg)
	local cursor_fg = gcolor.ensure_pango_color(args.cursor_fg)
	local placeholder_fg = gcolor.ensure_pango_color(args.placeholder_fg)

	if text ~= "" and highlighter then
		text_start, text_end = highlighter(text_start, text_end)
	end

	markup = prompt .. text_start ..
		"<span foreground='" .. cursor_fg .. "' background='" .. cursor_bg ..  "'>" .. cursor_char .. "</span>" ..
		(text == "" and "<span foreground='" .. placeholder_fg .. "'>" .. text_end .. "</span>" or text_end) ..
		spacer

	return markup
end

function text_input:set_obscure(obscure)
	self.obscure = obscure
	self:update_textbox()
end

function text_input:get_input()
	return self._private.input
end

function text_input:update_textbox()
	local wp = self._private
	self.textbox:set_markup(create_markup {
		text = wp.input,
		cursor_pos = wp.cur_pos,
		selectall = wp.selectall,
		obscure = self.obscure,
		cursor_bg = self.cursor_bg,
		cursor_fg = self.cursor_fg,
		placeholder_fg = self.placeholder_fg,
		obscure_char = self.obscure_char,
		prompt = self.prompt,
		placeholder = self.placeholder,
		highlighter = self.highlighter
	})
end

function text_input:run_keygrabber()
	local wp = self._private
	wp.keygrabber = awful.keygrabber.run(function(mods, key, event)
		local mod = {}
		for _, v in ipairs(mods) do
			mod[v] = true
		end

		if event ~= "press" then
			if self.keyreleased_callback then
				self.keyreleased_callback(mod, key, wp.input)
			end
			return
		end

		if self.keypressed_callback then
			self.keypressed_callback(mod, key, wp.input)
		end

		if mod.Control then
			if key == "a" then
				wp.cur_pos = 1
				wp.selectall = true
			elseif key == "c" then
				if wp.selectall then
					wp.clipboard:set_text(wp.input, -1)
					wp.cur_pos = utf8.len(wp.input) + 1
					wp.selectall = false
				end
			elseif key == "v" then
				wp.clipboard:request_text(function(_, text)
					if text then
						if wp.selectall then
							wp.input = text
							wp.selectall = false
						else
							wp.input = utf8.sub(wp.input, 1, wp.cur_pos - 1) ..
								text .. utf8.sub(wp.input, wp.cur_pos)
						end
						wp.cur_pos = wp.cur_pos + utf8.len(text)
						if self.changed_callback then
							self.changed_callback(wp.input)
						end
						self:update_textbox()
					end
				end)
			end
		else
			if key == "Escape" then
				wp.selectall = false
				self:stop_keygrabber()
				if self.done_callback then
					self.done_callback()
				end
				return
			elseif key == "Return" then
				if self.exe_callback then
					self.exe_callback(wp.input)
				end
				wp.selectall = false
				self:stop_keygrabber()
				if self.done_callback then
					self.done_callback()
				end
				return
			elseif key == "Home" then
				wp.selectall = false
				wp.cur_pos = 1
			elseif key == "End" then
				wp.selectall = false
				wp.cur_pos = utf8.len(wp.input) + 1
			elseif key == "Left" then
				wp.selectall = false
				if wp.cur_pos > 1 then
					wp.cur_pos = wp.cur_pos - 1
				end
			elseif key == "Right" then
				if wp.selectall then
					wp.selectall = false
					wp.cur_pos = utf8.len(wp.input) + 1
				elseif wp.cur_pos < utf8.len(wp.input) + 1 then
					wp.cur_pos = wp.cur_pos + 1
				end
			elseif key == "Delete" then
				if wp.selectall then
					wp.input = ""
					wp.selectall = false
					if self.changed_callback then
						self.changed_callback(wp.input)
					end
				elseif wp.cur_pos < utf8.len(wp.input) + 1 then
					wp.input = utf8.sub(wp.input, 1, wp.cur_pos - 1) ..
						utf8.sub(wp.input, wp.cur_pos + 1)
					if self.changed_callback then
						self.changed_callback(wp.input)
					end
				end
			elseif key == "BackSpace" then
				if wp.selectall then
					wp.input = ""
					wp.selectall = false
					if self.changed_callback then
						self.changed_callback(wp.input)
					end
				elseif wp.cur_pos > 1 then
					wp.input = utf8.sub(wp.input, 1, wp.cur_pos - 2) ..
						utf8.sub(wp.input, wp.cur_pos)
					wp.cur_pos = wp.cur_pos - 1
					if self.changed_callback then
						self.changed_callback(wp.input)
					end
				end
			elseif utf8.len(key) == 1 then
				if wp.selectall then
					wp.input = key
					wp.selectall = false
				else
					wp.input = utf8.sub(wp.input, 1, wp.cur_pos - 1) .. key ..
						utf8.sub(wp.input, wp.cur_pos)
					wp.cur_pos = wp.cur_pos + 1
				end
				if self.changed_callback then
					self.changed_callback(wp.input)
				end
			end
		end

		self:update_textbox()
	end)

	wp.cur_pos = 1
	wp.input = ""
	self:update_textbox()
end

function text_input:stop_keygrabber()
	local wp = self._private
	awful.keygrabber.stop(wp.keygrabber)
	wp.input = ""
	wp.cur_pos = 1
	self:update_textbox()
end

local function new(args)
	local ret = {}
	gtable.crush(ret, text_input, true)

	args = args or {}
	if not args.textbox then return end

	ret._private = {}
	local wp = ret._private

	wp.input = ""
	wp.cur_pos = 1
	wp.selectall = false
	wp.clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)

	ret.textbox = args.textbox
	ret.obscure = args.obscure or false
	ret.prompt = args.prompt or ""
	ret.placeholder = args.placeholder or ""
	ret.obscure_char = args.obscure_char or "*"
	ret.cursor_bg = args.cursor_bg or "#ffffff"
	ret.cursor_fg = args.cursor_fg or "#000000"
	ret.placeholder_fg = args.placeholder_fg or "#373737"
	ret.done_callback = args.done_callback
	ret.exe_callback = args.exe_callback
	ret.changed_callback = args.changed_callback
	ret.keyreleased_callback = args.keyreleased_callback
	ret.keypressed_callback = args.keypressed_callback
	ret.highlighter = args.highlighter

	return ret
end

return setmetatable(text_input, {
	__call = function(_, ...)
		return new(...)
	end
})
