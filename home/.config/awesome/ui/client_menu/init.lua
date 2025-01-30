local awful = require("awful")
local gtimer = require("gears.timer")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local client_menu = {}

local function create_menu(c)
	local move_to_tag_item = {}
	local toggle_on_tag_item = {}

	for _, t in ipairs(c.screen.tags) do
		table.insert(move_to_tag_item, { t.name, function()
			c:move_to_tag(t)
		end })
		table.insert(toggle_on_tag_item, { t.name, function()
			c:toggle_tag(t)
		end })
	end

	local cmenu = awful.menu {
		auto_expand = true,
		theme = {
			font = beautiful.font_h0,
			width = dpi(180),
			height = dpi(25)
		},
		items = {
			{ "move to tag", move_to_tag_item },
			{ "toggle on tag", toggle_on_tag_item },
			{ "toggle titlebar", function()
				if c.requests_no_titlebar then
					return
				else
					awful.titlebar.toggle(c, "top")
				end
			end },
			{ "move to center", function()
				awful.placement.centered(c, { honor_workarea = true })
			end },
			{ c.ontop and "unset ontop" or "set ontop", function()
				c.ontop = not c.ontop
			end },
			{ c.fullscreen and "unset fullscreen" or "set fullscreen", function()
				c.fullscreen = not c.fullscreen
				c:activate()
			end },
			{ c.maximized and "unmaximize" or "maximize", function()
				c.maximized = not c.maximized
				c:activate()
			end },
			{ c.minimized and "unminimize" or "minimize", function()
				gtimer.delayed_call(function()
					if c.minimized then
						c.minimized = false
						c:activate()
					else
						c.minimized = true
					end
				end)
			end },
			{ "close", function()
				c:kill()
			end }
		}
	}

	return cmenu
end

function client_menu:hide()
	if self._menu and self._menu.wibox.visible then
		self._menu:hide()
		self._menu = nil
	end
end

function client_menu:show(c)
	c = c or client.focus
	if not c then return end
	if self._menu then
		if not self._menu.wibox.visible then
			self._menu = create_menu(c)
			self._menu:show()
		end
	else
		self._menu = create_menu(c)
		self._menu:show()
	end
end

function client_menu:toggle(c)
	c = c or client.focus
	if not c then return end
	if self._menu then
		if self._menu.wibox.visible then
			self._menu:hide()
			self._menu = nil
		else
			self._menu = create_menu(c)
			self._menu:show()
		end
	else
		self._menu = create_menu(c)
		self._menu:show()
	end
end

return client_menu
