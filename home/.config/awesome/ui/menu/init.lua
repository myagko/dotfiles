local Gio = require("lgi").require("Gio")
local awful = require("awful")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gfs = require("gears.filesystem")
local user = require("user")
local dpi = beautiful.xresources.apply_dpi
local is_supported = require("lib").is_supported
local table_to_file = require("lib").table_to_file
local capi = { awesome = awesome, screen = screen, client = client }
local screenshot = require("service.screenshot").get_default()
local powermenu = require("ui.powermenu").get_default()

local menu = {}

local function create_desktop_menu()
	return awful.menu {
		auto_expand = true,
		theme = {
			width = dpi(160),
			height = dpi(25),
			--shape = beautiful.rrect(dpi(10)),
			font = beautiful.font_h0
		},
		items = {
			{
				"awesome",
				{
					{
						"config",
						function()
							local app = Gio.AppInfo.get_default_for_type("inode/directory")
							if app then
								awful.spawn(string.format(
									"%s %s",
									app:get_executable(),
									gfs.get_configuration_dir()
								))
							end
						end
					},
					{
						"set wallpaper",
						function()
							awful.spawn.easy_async("zenity --file-selection", function(stdout)
								stdout = string.gsub(stdout, "\n", "")
								local formats = { "png", "jpg", "jpeg" }
								if stdout ~= nil and stdout ~= "" and is_supported(stdout, formats) then
									for s in capi.screen do
										s.wallpaper:set_image(stdout)
									end
									user.wallpaper = stdout
									table_to_file(user, gfs.get_configuration_dir() .. "/user.lua")
								end
							end)
						end
					},
					{
						"restart",
						function()
							capi.awesome.restart()
						end
					},
					{
						"power",
						function()
							powermenu:toggle()
						end
					}
				}
			},
			{
				"screenshot",
				{
					{
						"full",
						function()
							screenshot:take_full()
						end
					},
					{
						"full 5s delay",
						function()
							screenshot:take_delay(5)
						end
					},
					{
						"select area",
						function()
							screenshot:take_select()
						end
					}
				}
			},
			{
				"terminal",
				function()
					local app = Gio.AppInfo.get_default_for_uri_scheme('terminal')
					if app then awful.spawn(app:get_executable()) end
				end
			},
			{
				"files",
				function()
					local app = Gio.AppInfo.get_default_for_type("inode/directory")
					if app then awful.spawn(app:get_executable()) end
				end
			},
			{
				"web",
				function()
					local app = Gio.AppInfo.get_default_for_type("text/html")
					if app then awful.spawn(app:get_executable()) end
				end
			}
		}
	}
end

local function create_client_menu(c)
	local move_to_tag_item = {}
	local toggle_on_tag_item = {}

	for _, t in ipairs(c.screen.tags) do
		table.insert(move_to_tag_item, {
			string.format("%s: %s", t.index, t.name),
			function()
				c:move_to_tag(t)
			end
		})
		table.insert(toggle_on_tag_item, {
			string.format("%s: %s", t.index, t.name),
			function()
				c:toggle_tag(t)
			end
		})
	end

	return awful.menu {
		auto_expand = true,
		theme = {
			width = dpi(180),
			height = dpi(25),
			--shape = beautiful.rrect(dpi(10)),
			font = beautiful.font_h0
		},
		items = {
			{
				"move to tag",
				move_to_tag_item
			},
			{
				"toggle on tag",
				toggle_on_tag_item
			},
			not c.requests_no_titlebar and {
				"toggle titlebar",
				function()
					awful.titlebar.toggle(c, "top")
				end
			},
			{
				"move to center",
				function()
					awful.placement.centered(c, { honor_workarea = true })
				end
			},
			{
				c.ontop and "unset ontop" or "set ontop",
				function()
					c.ontop = not c.ontop
				end
			},
			{
				c.fullscreen and "unset fullscreen" or "set fullscreen",
				function()
					c.fullscreen = not c.fullscreen
					c:activate()
				end
			},
			{
				c.maximized and "unmaximize" or "maximize",
				function()
					c.maximized = not c.maximized
					c:activate()
				end
			},
			{
				c.minimized and "unminimize" or "minimize",
				function()
					gtimer.delayed_call(function()
						if c.minimized then
							c.minimized = false
							c:activate()
						else
							c.minimized = true
						end
					end)
				end
			},
			{
				"close",
				function()
					c:kill()
				end
			}
		}
	}
end

function menu:hide()
	if self.menu_widget and self.menu_widget.wibox.visible then
		self.menu_widget:hide()
		self.menu_widget = nil
	end
end

function menu:show_desktop_menu()
	if self.menu_widget then
		if not self.menu_widget.wibox.visible then
			self.menu_widget = create_desktop_menu()
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_desktop_menu()
		self.menu_widget:show()
	end
end

function menu:toggle_desktop_menu()
	if self.menu_widget then
		if self.menu_widget.wibox.visible then
			self.menu_widget:hide()
			self.menu_widget = nil
		else
			self.menu_widget = create_desktop_menu()
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_desktop_menu()
		self.menu_widget:show()
	end
end

function menu:show_client_menu(c)
	c = c or capi.client.focus
	if not c then return end
	if self.menu_widget then
		if not self.menu_widget.wibox.visible then
			self.menu_widget = create_client_menu(c)
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_client_menu(c)
		self.menu_widget:show()
	end
end

function menu:toggle_client_menu(c)
	c = c or capi.client.focus
	if not c then return end
	if self.menu_widget then
		if self.menu_widget.wibox.visible then
			self.menu_widget:hide()
			self.menu_widget = nil
		else
			self.menu_widget = create_client_menu(c)
			self.menu_widget:show()
		end
	else
		self.menu_widget = create_client_menu(c)
		self.menu_widget:show()
	end
end

local function new()
	local ret = {}
	gtable.crush(ret, menu, true)
	ret.menu_widget = create_desktop_menu()
	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return {
	get_default = get_default
}
