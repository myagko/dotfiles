local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local user = require("user")

local themes = {
	["everblush"] = true,
	["gruvbox"] = true,
	["haven"] = true,
	["placid"] = true,
	["nymph"] = true,
	["astel"] = true
}

local theme_name = themes[user.theme] and user.theme or "everblush"
beautiful.init(gfilesystem.get_configuration_dir() .. "themes/" .. theme_name .. "/theme.lua")
