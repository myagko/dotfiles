local astal = require("astal")
local Variable = require("astal").Variable
local Gtk = require("astal.gtk3").Gtk
local GLib = astal.require("GLib")

local M = {}

function M.src(path)
	local str = debug.getinfo(2, "S").source:sub(2)
	local src = str:match("(.*/)") or str:match("(.*\\)") or "./"
	return src .. path
end

function M.map(array, func)
	local new_arr = {}
	for i, v in ipairs(array) do
		new_arr[i] = func(v, i)
	end
	return new_arr
end

function M.varmap(initial)
	local map = initial
	local var = Variable()

	local function var_set()
		local arr = {}
		for _, value in pairs(map) do
			table.insert(arr, value)
		end
		var:set(arr)
	end

	local function var_delete(key)
		if Gtk.Widget:is_type_of(map[key]) then
			map[key]:destroy()
		end
		map[key] = nil
	end

	var_set()

	return setmetatable({
		set = function(key, value)
			var_delete(key)
			map[key] = value
			var_set()
		end,
		delete = function(key)
			var_delete(key)
			var_set()
		end,
		get = function()
			return var:get()
		end,
		subscribe = function(callback)
			return var:subscribe(callback)
		end,
	}, {
		__call = function()
			return var()
		end
	})
end

function M.file_exists(path)
	return GLib.file_test(path, "EXISTS")
end

function M.time(time, format)
	format = format or "%H:%M"
	return GLib.DateTime.new_from_unix_local(time):format(format)
end

function M.lua_escape(str)
	return str:gsub("[%[%]%(%)%.%-%+%?%*%%]", "%%%1")
end

return M
