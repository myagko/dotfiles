#!/bin/lua

local home = os.getenv("HOME")
local moz_default = "tm9d9sgu.default-release"
local themes = {
	["haven"] = true,
	["nymph"] = true,
	["gruvbox"] = true,
	["everblush"] = true
}

local function editlines(file, pattern, repl)
	local rfile = assert(io.open(file, "r"))
	local lines = {}
	for line in rfile:lines() do
		local rep = line:gsub(pattern, repl)
		table.insert(lines, rep)
	end
	rfile:close()
	local wfile = assert(io.open(file, "w"))
	for _, line in ipairs(lines) do
		wfile:write(line .. "\n")
	end
	wfile:close()
end

local newtheme = arg[1]

if themes[newtheme] then
	editlines(home .. "/.config/awesome/user.lua", "(.*theme = \").*(\")", "%1" .. newtheme .. "%2")
	editlines(home .. "/.config/alacritty/alacritty.toml", "(.*/.config/alacritty/themes/).*(%.toml.*)", "%1" .. newtheme .. "%2" )
	editlines(home .. "/.mozilla/firefox/" .. moz_default .. "/chrome/userChrome.css", "(@import url%(\"themes/).*(_theme.css\"%);)", "%1" .. newtheme .. "%2")
	editlines(home .. "/.mozilla/startpage/index.css", "(@import url%(\"themes/).*(_theme.css\"%);)", "%1" .. newtheme .. "%2")
else
	print("Wrong theme name.")
end
