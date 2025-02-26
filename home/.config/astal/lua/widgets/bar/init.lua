local astal = require("astal")
local Variable = astal.Variable
local bind = astal.bind
local GLib = astal.require("GLib")
local AstalHyprland = astal.require("AstalHyprland")
local AstalTray = astal.require("AstalTray")
local gtkApp = require("astal.gtk3").App
local gtkWidget = require("astal.gtk3").Widget
local gtkAstal = require("astal.gtk3").Astal
local map = require("lua.lib").map
local text_icons = require("lua.text_icons")

local hyprland = AstalHyprland.get_default()
local tray = AstalTray.get_default()

local function LauncherButton()
	return gtkWidget.Button {
		class_name = "launcher-button",
		on_clicked = function()
			local launcher = gtkApp:get_window("Launcher")
			if launcher then launcher:show() end
		end,
		gtkWidget.Label {
			label = text_icons.menu
		}
	}
end

local function Workspaces()
	return gtkWidget.Box {
		class_name = "workspaces",
		bind(hyprland, "workspaces"):as(function(ws)
			table.sort(ws, function(a, b) return a.id < b.id end)
			return map(ws, function(w)
				return not (w.id >= -99 and w.id <= -2) and gtkWidget.Button {
					class_name = bind(hyprland, "focused-workspace"):as(function(fw)
						return "workspace " .. (fw == w and "focused" or "")
					end),
					on_clicked = function()
						if w ~= hyprland:get_focused_workspace() then
							w:focus()
						end
					end,
					label = bind(w, "id"):as(function(id)
						return type(id) == "number" and string.format("%.0f", id) or id
					end)
				}
			end)
		end)
	}
end

local function Clients()
	return gtkWidget.Box {
		class_name = "clients",
		spacing = 6,
		expand = false,
		bind(hyprland, "clients"):as(function(cs)
			return map(cs, function(c)
				return gtkWidget.Button {
					class_name = bind(hyprland, "focused-client"):as(function(fc)
						return "client " .. (fc == c and "focused" or "" )
					end),
					visible = bind(hyprland, "focused-workspace"):as(function(fw)
						return fw == c:get_workspace()
					end),
					on_click = function(_, event)
						if event.button == "PRIMARY" then
							if c ~= hyprland:get_focused_client() then
								c:focus()
							end
							if c:get_floating() then
								hyprland:dispatch("alterzorder", "top, " .. c:get_address())
							end
						elseif event.button == "MIDDLE" then
							c:kill()
						end
					end,
					setup = function(self)
						self:hook(c, "moved-to", function(_, ws)
							self:set_visible(ws == hyprland:get_focused_workspace())
						end)
					end,
					gtkWidget.Label {
						max_width_chars = 15,
						ellipsize = "END",
						label = bind(c, "title"):as(function(t)
							return (t ~= nil and t ~= "") and t or "untitled"
						end)
					}
				}
			end)
		end)
	}
end

local function KbLayout()
	local layout_name = Variable("En")

	return gtkWidget.Box {
		class_name = "kblayout",
		setup = function(self)
			self:hook(hyprland, "keyboard-layout", function(_, _, lt)
				local lt_name = (lt:match("English") and "En") or
					(lt:match("Russian") and "Ru") or "??"
				layout_name:set(lt_name)
			end)
		end,
		gtkWidget.Label {
			label = layout_name()
		}
	}
end

local function SysTray()
	local tray_visibility = Variable()

	return gtkWidget.Box {
		class_name = "systray",
		gtkWidget.Button {
			class_name = "reveal-button",
			on_clicked = function()
				tray_visibility:set(not tray_visibility:get())
			end,
			gtkWidget.Label {
				label = bind(tray_visibility):as(function(v)
					return v and text_icons.arrow_right or text_icons.arrow_left
				end)
			}
		},
		gtkWidget.Revealer {
			reveal_child = bind(tray_visibility),
			transition_type = "SLIDE_LEFT",
			gtkWidget.Box {
				bind(tray, "items"):as(function(items)
					return map(items, function(item)
						return gtkWidget.MenuButton {
							class_name = "item",
							tooltip_markup = bind(item, "tooltip_markup"),
							use_popover = false,
							menu_model = bind(item, "menu-model"),
							action_group = bind(item, "action-group"):as(function(ag)
								return { "dbusmenu", ag }
							end),
							gtkWidget.Icon {
								gicon = bind(item, "gicon")
							}
						}
					end)
				end)
			}
		}
	}
end

local function Time(format)
	local time = Variable(""):poll(1000, function()
		return GLib.DateTime.new_now_local():format(format)
	end)

	return gtkWidget.Box {
		class_name = "time",
		gtkWidget.Label {
			on_destroy = function()
				time:drop()
			end,
			label = time(),
		}
	}
end

local function ControlPanelButton()
	return gtkWidget.Button {
		class_name = "control-panel-button",
		on_clicked = function()
			local panel = gtkApp:get_window("Control-panel")
			if panel then panel:show() end
		end,
		gtkWidget.Label {
			label = text_icons.sliders
		}
	}
end

return function(gdkmonitor)
	local Anchor = gtkAstal.WindowAnchor
	return gtkWidget.Window {
		name = "Bar",
		class_name = "bar",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.BOTTOM + Anchor.LEFT + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		gtkWidget.CenterBox {
			class_name = "mainbox",
			spacing = 6,
			gtkWidget.Box {
				halign = "START",
				spacing = 6,
				LauncherButton(),
				Workspaces(),
			},
			gtkWidget.Box {
				Clients()
			},
			gtkWidget.Box {
				halign = "END",
				spacing = 6,
				SysTray(),
				KbLayout(),
				Time("%e %b, %a - %H:%M"),
				ControlPanelButton()
			}
		}
	}
end
