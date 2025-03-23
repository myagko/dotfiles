local utf8 = require("lua-utf8")
local Gio = require("lgi").Gio
local astal = require("astal")
local Variable = astal.Variable
local bind = astal.bind
local AstalHyprland = astal.require("AstalHyprland")
local App = require("astal.gtk3").App
local Widget = require("astal.gtk3").Widget
local Astal = require("astal.gtk3").Astal
local Gdk = require("astal.gtk3").Gdk
local map = require("lua.lib").map
local lua_escape = require("lua.lib").lua_escape

local hyprland = AstalHyprland.get_default()
local TERMINAL = "alacritty"

local terminal_cmds = {
	alacritty = "alacritty -e ",
	termite = "termite -e ",
	rxvt = "rxvt -e ",
	terminator = "terminator -e "
}

local function launch_app(app)
	local terminal_cmd = TERMINAL and terminal_cmds[TERMINAL] or nil
	local desktop_app_info = Gio.DesktopAppInfo.new(Gio.AppInfo.get_id(app))
	local terminal = Gio.DesktopAppInfo.get_string(desktop_app_info, "Terminal") == "true" and true or false

	--hyprland:dispatch("exec", (terminal and terminal_cmd or "") .. app:get_executable())
	if terminal and terminal_cmd then
		hyprland:dispatch("exec", (terminal and terminal_cmd or "") .. app:get_executable())
	else
		app:launch()
	end
end

local function filter_apps(apps, query)
	query = lua_escape(query)
	local filtered = {}
	local filtered_any = {}

	for _, app in ipairs(apps) do
		if app:should_show() then
			local name_match = utf8.lower(utf8.sub(app:get_name(), 1, utf8.len(query))) == utf8.lower(query)
			local name_match_any = utf8.match(utf8.lower(app:get_name()), utf8.lower(query))
			local exec_match_any = utf8.match(string.lower(app:get_executable()), utf8.lower(query))

			if name_match then
				table.insert(filtered, app)
			elseif name_match_any or exec_match_any then
				table.insert(filtered_any, app)
			end
		end
	end

	table.sort(filtered, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	table.sort(filtered_any, function(a, b)
		return utf8.lower(a:get_name()) < utf8.lower(b:get_name())
	end)

	for i = 1, #filtered_any do
		filtered[#filtered + 1] = filtered_any[i]
	end

	return filtered
end

local function hide_launcher()
	local launcher = App:get_window("Launcher")
	if launcher then launcher:hide() end
end

local function AppButton(app)
	return Widget.Button {
		class_name = "app-button",
		on_clicked = function()
			launch_app(app)
			hide_launcher()
		end,
		Widget.Label {
			class_name = "name",
			xalign = 0,
			ellipsize = "END",
			label = app:get_name()
		}
	}
end

return function()
	local apps = Gio.AppInfo.get_all()
	local app_query = Variable("")
	local app_list = bind(app_query):as(function(text)
		return filter_apps(apps, text)
	end)

	local on_enter = function()
		local first_app = filter_apps(apps, app_query:get())[1]
		if first_app then
			launch_app(first_app)
			hide_launcher()
		end
	end

	local entry = Widget.Entry {
		placeholder_text = "Search...",
		text = bind(app_query):as(function(text)
			return tostring(text)
		end),
		on_changed = function(self)
			app_query:set(self.text)
		end,
		on_activate = on_enter
	}

	local Anchor = Astal.WindowAnchor
	return Widget.Window {
		name = "Launcher",
		class_name = "launcher",
		anchor = Anchor.BOTTOM + Anchor.LEFT,
		exclusivity = "EXCLUSIVE",
		keymode = "ON_DEMAND",
		application = App,
		visible = false,
		on_show = function()
			app_query:set("")
		end,
		on_key_press_event = function(self, event)
			if event.keyval == Gdk.KEY_Escape then
				self:hide()
			end
		end,
		setup = function(self)
			self:hook(self, "notify::visible", function()
				if self.visible then
					apps = Gio.AppInfo.get_all()
					entry:set_position(-1)
					entry:select_region(0, -1)
					entry:grab_focus()
				end
			end)
		end,
		Widget.Box {
			Widget.Box {
				hexpand = false,
				vertical = true,
				Widget.EventBox {
					on_click = hide_launcher,
					height_request = 1000
				},
				Widget.Box {
					vertical = true,
					width_request = 400,
					height_request = 480,
					class_name = "mainbox",
					entry,
					Widget.Scrollable {
						expand = true,
						Widget.Box {
							vertical = true,
							spacing = 3,
							app_list:as(function(list)
								return map(list, function(app)
									return AppButton(app)
								end)
							end),
							Widget.Box {
								class_name = "not-found",
								halign = "CENTER",
								valign = "CENTER",
								expand = true,
								visible = app_list:as(function(list)
									return #list == 0
								end),
								Widget.Label {
									label = "No match found"
								}
							}
						}
					}
				}
			},
			Widget.EventBox {
				width_request = 4000,
				expand = true,
				on_click = hide_launcher
			}
		}
	}
end
