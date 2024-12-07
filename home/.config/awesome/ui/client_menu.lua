local awful = require("awful")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local client_menu = {}

local function create_menu(c)
	local move_to_tag_item = {}

	for _, t in ipairs(c.screen.tags) do
		table.insert(move_to_tag_item, { t.index .. ":" .. t.name, function()
			c:move_to_tag(t)
		end })
	end

	local cmenu = awful.menu {
		auto_expand = true,
		theme = {
			font = beautiful.font_h0,
			width = dpi(150),
			height = dpi(25)
		},
		items = {
			{ "move to tag", move_to_tag_item },
			{ "titlebar", function()
				if c.requests_no_titlebar then
					return
				else
					awful.titlebar.toggle(c, "top")
				end
			end },
			{ "center", function()
				awful.placement.centered(c, { honor_workarea = true })
			end },
			{ "ontop", function()
				c.ontop = not c.ontop
			end },
			{ "floating", function()
				awful.client.floating.toggle(c)
			end },
			{ "fullscreen", function()
				c.fullscreen = not c.fullscreen
			end },
			{ "maximize", function()
				c.maximized = not c.maximized
				c:raise()
			end },
			{ "minimize", function()
				gtimer.delayed_call(function()
					c.minimized = true
				end)
			end },
			{ "close", function()
				c:kill()
			end }
		}
	}

	return cmenu
end

function client_menu:toggle(c)
	self._menu = create_menu(c)
	self._menu:toggle()
end

return client_menu
