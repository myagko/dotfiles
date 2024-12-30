local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local user = require("user")

beautiful.init(gfilesystem.get_configuration_dir() .. "themes/" .. (user.theme or "everblush") .. "/theme.lua")
