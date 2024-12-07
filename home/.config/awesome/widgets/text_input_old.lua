local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")
local Gdk = lgi.require("Gdk", "3.0")
local awful = require("awful")
local gtable = require("gears.table")
local gstring = require("gears.string")
local gcolor = require("gears.color")

local text_input = { mt = {} }

local utf8_char_match = "[\0-\x7F\xC2-\xF4][\x80-\xBF]*"

local function have_multibyte_char_at(text, position)
	return text:sub(position, position):wlen() == -1
end

local function draw_text(args)
	local text = args.text or ""
	local cursor_pos = args.cursor_pos or 1
	local selectall = args.selectall or false
	local start_prompt = args.start_prompt or ""
	local under_prompt = args.under_prompt or ""
	local obscure = args.obscure or false
	local obscure_char = args.obscure_char or "*"
	local cursor_char, spacer, text_start, text_end, draw

	if text == "" and under_prompt ~= "" then
		local offset = 0
		if have_multibyte_char_at(under_prompt, 1) then
			offset = 1
		end
		spacer = ""
		cursor_char = gstring.xml_escape(under_prompt:sub(cursor_pos, cursor_pos + offset))
		text_start = ""
		text_end = gstring.xml_escape(under_prompt:sub(2 + offset))
	elseif selectall then
		if text == "" then
			cursor_char = " "
		else
			cursor_char = gstring.xml_escape(obscure and
				text:gsub(utf8_char_match, obscure_char) or text)
		end
		spacer = " "
		text_start = ""
		text_end = ""
	elseif #text < cursor_pos then
		cursor_char = " "
		spacer = ""
		text_start = gstring.xml_escape(obscure and
			text:gsub(utf8_char_match, obscure_char) or text)
		text_end = ""
	else
		local offset = 0
		if have_multibyte_char_at(text, cursor_pos) then
			offset = 1
		end
		cursor_char = gstring.xml_escape(obscure and
			text:sub(cursor_pos, cursor_pos + offset):gsub(utf8_char_match, obscure_char) or
			text:sub(cursor_pos, cursor_pos + offset))
		spacer = " "
		text_start = gstring.xml_escape(obscure and
			text:sub(1, cursor_pos - 1):gsub(utf8_char_match, obscure_char) or
			text:sub(1, cursor_pos - 1))
		text_end = gstring.xml_escape(obscure and
			text:sub(cursor_pos + 1 + offset):gsub(utf8_char_match, obscure_char) or
			text:sub(cursor_pos + 1 + offset))
	end

	local cursor_bg = gcolor.ensure_pango_color(args.cursor_bg)
	local cursor_fg = gcolor.ensure_pango_color(args.cursor_fg)
	local under_prompt_fg = gcolor.ensure_pango_color(args.under_prompt_fg)

	draw = start_prompt .. text_start ..
		"<span foreground='" .. cursor_fg .. "' background='" .. cursor_bg ..  "'>" .. cursor_char .. "</span>" ..
		(text == "" and "<span foreground='" .. under_prompt_fg .. "'>" .. text_end .. "</span>" or text_end) ..
		spacer

	return draw
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
	self.textbox:set_markup(draw_text {
		text = wp.input,
		cursor_pos = wp.cur_pos,
		selectall = wp.selectall,
		obscure = self.obscure,
		cursor_bg = self.cursor_bg,
		cursor_fg = self.cursor_fg,
		under_prompt_fg = self.under_prompt_fg,
		obscure_char = self.obscure_char,
		start_prompt = self.start_prompt,
		under_prompt = self.under_prompt
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
					wp.cur_pos = #wp.input + 1
					wp.selectall = false
				end
			elseif key == "v" then
				wp.clipboard:request_text(function(_, text)
					if text then
						if wp.selectall then
							wp.input = text
							wp.selectall = false
						else
							wp.input = wp.input:sub(1, wp.cur_pos - 1) ..
								text .. wp.input:sub(wp.cur_pos)
						end
						wp.cur_pos = wp.cur_pos + #text
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
				wp.cur_pos = #wp.input + 1
			elseif key == "Left" then
				wp.selectall = false
				local offset = 0
				if have_multibyte_char_at(wp.input, wp.cur_pos - 1) then
					offset = 1
				end
				wp.cur_pos = wp.cur_pos - 1 - offset
			elseif key == "Right" then
				if wp.selectall then
					wp.selectall = false
					wp.cur_pos = #wp.input + 1
				else
					local offset = 0
					if have_multibyte_char_at(wp.input, wp.cur_pos) then
						offset = 1
					end
					wp.cur_pos = wp.cur_pos + 1 + offset
				end
			elseif key == "Delete" then
				if wp.selectall then
					wp.input = ""
					wp.selectall = false
				else
					local offset = 0
					if have_multibyte_char_at(wp.input, wp.cur_pos) then
						offset = 1
					end
					wp.input = wp.input:sub(1, wp.cur_pos - 1) ..
						wp.input:sub(wp.cur_pos + 1 + offset)
				end
				if self.changed_callback then
					self.changed_callback(wp.input)
				end
			elseif key == "BackSpace" then
				if wp.selectall then
					wp.input = ""
					wp.selectall = false
				else
					if wp.cur_pos > 1 then
						local offset = 0
						if have_multibyte_char_at(wp.input, wp.cur_pos - 1) then
							offset = 1
						end
						wp.input = wp.input:sub(1, wp.cur_pos - 2 - offset) ..
							wp.input:sub(wp.cur_pos)
						wp.cur_pos = wp.cur_pos - 1 - offset
					end
				end
				if self.changed_callback then
					self.changed_callback(wp.input)
				end
			elseif key:wlen() == 1 then
				if wp.selectall then
					wp.input = key
					wp.selectall = false
				else
					wp.input = wp.input:sub(1, wp.cur_pos - 1) .. key ..
						wp.input:sub(wp.cur_pos)
				end
				wp.cur_pos = wp.cur_pos + #key
				if self.changed_callback then
					self.changed_callback(wp.input)
				end
			end

			if wp.cur_pos < 1 then
				wp.cur_pos = 1
			elseif wp.cur_pos > #wp.input + 1 then
				wp.cur_pos = #wp.input + 1
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
	ret.start_prompt = args.start_prompt or ""
	ret.under_prompt = args.under_prompt or ""
	ret.obscure_char = args.obscure_char or "*"
	ret.cursor_bg = args.cursor_bg or "#ffffff"
	ret.cursor_fg = args.cursor_fg or "#000000"
	ret.under_prompt_fg = args.under_prompt_fg or "#373737"
	ret.done_callback = args.done_callback or nil
	ret.exe_callback = args.exe_callback or nil
	ret.changed_callback = args.changed_callback or nil
	ret.keyreleased_callback = args.keyreleased_callback or nil
	ret.keypressed_callback = args.keypressed_callback or nil

	return ret
end

function text_input.mt:__call(...)
	return new(...)
end

return setmetatable(text_input, text_input.mt)
