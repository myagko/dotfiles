local Gio = require("lgi").Gio
local awful = require("awful")
local beautiful = require("beautiful")
local gfilesystem = require("gears.filesystem")
local gtimer = require("gears.timer")
local screenshot = require("services.screenshot")
local user = require("user")
local dpi = beautiful.xresources.apply_dpi
local capi = { awesome = awesome, client = client }

local powermenu = require("ui.powermenu")

local menu = {}

local function create_desktop_menu()
	return awful.menu {
		auto_expand = true,
		theme = {
			width = dpi(160),
			height = dpi(25),
			shape = beautiful.rrect(dpi(10)),
			font = beautiful.font_h0
		},
		items = {
			{ "awesome", {
				{ "config", function() awful.spawn("xdg-open " .. gfilesystem.get_configuration_dir()) end },
				{ "restart", function() capi.awesome.emit_signal("request::restart") end },
				{ "power", function() powermenu:toggle() end }
			} },
			{ "screenshot", {
				{ "full", function() screenshot:take_full() end },
				{ "full 5s delay", function() screenshot:take_delay(5) end },
				{ "select area", function() screenshot:take_select() end }
			} },
			{ "terminal", function() awful.spawn(user.terminal) end },
			{ "files", function() awful.spawn("xdg-open " .. os.getenv("HOME")) end },
			{ "web", function()
				local app = Gio.AppInfo.get_default_for_type("text/html")
				app:launch()
			end }
		}
	}
end

local function create_client_menu(c)
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

	return awful.menu {
		auto_expand = true,
		theme = {
			width = dpi(180),
			height = dpi(25),
			shape = beautiful.rrect(dpi(10)),
			font = beautiful.font_h0
		},
		items = {
			{ "move to tag", move_to_tag_item },
			{ "toggle on tag", toggle_on_tag_item },
			not c.requests_no_titlebar and { "toggle titlebar", function()
				awful.titlebar.toggle(c, "top")
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
end

function menu:hide()
	if self._menu and self._menu.wibox.visible then
		self._menu:hide()
		self._menu = nil
	end
end

function menu:show_desktop_menu()
	if self._menu then
		if not self._menu.wibox.visible then
			self._menu = create_desktop_menu()
			self._menu:show()
		end
	else
		self._menu = create_desktop_menu()
		self._menu:show()
	end
end

function menu:toggle_desktop_menu()
	if self._menu then
		if self._menu.wibox.visible then
			self._menu:hide()
			self._menu = nil
		else
			self._menu = create_desktop_menu()
			self._menu:show()
		end
	else
		self._menu = create_desktop_menu()
		self._menu:show()
	end
end

function menu:show_client_menu(c)
	c = c or capi.client.focus
	if not c then return end
	if self._menu then
		if not self._menu.wibox.visible then
			self._menu = create_client_menu(c)
			self._menu:show()
		end
	else
		self._menu = create_client_menu(c)
		self._menu:show()
	end
end

function menu:toggle_client_menu(c)
	c = c or capi.client.focus
	if not c then return end
	if self._menu then
		if self._menu.wibox.visible then
			self._menu:hide()
			self._menu = nil
		else
			self._menu = create_client_menu(c)
			self._menu:show()
		end
	else
		self._menu = create_client_menu(c)
		self._menu:show()
	end
end

return menu
