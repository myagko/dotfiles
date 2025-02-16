local astal = require("astal")
local Variable = astal.Variable
local bind = astal.bind
local gtkWidget = require("astal.gtk3.widget")
local GLib = astal.require("GLib")
local map = require("lib").map
local Hyprland = astal.require("AstalHyprland")
local Tray = astal.require("AstalTray")

local hyprland = Hyprland.get_default()
local tray = Tray.get_default()

local function Workspaces()
	return gtkWidget.Box {
		class_name = "workspaces",
		bind(hyprland, "workspaces"):as(function(wss)
			table.sort(wss, function(a, b) return a.id < b.id end)
			return map(wss, function(ws)
				if not (ws.id >= -99 and ws.id <= -2) then
					return gtkWidget.Button {
						class_name = bind(hyprland, "focused-workspace"):as(function(fw)
							return "workspace " .. (fw == ws and "focused" or "")
						end),
						on_clicked = function()
							ws:focus()
						end,
						label = bind(ws, "id"):as(function(v)
							return type(v) == "number" and string.format("%.0f", v) or v
						end)
					}
				end
			end)
		end)
	}
end

local function Clients()
	return gtkWidget.Box {
		class_name = "clients",
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
								if c:get_floating() then
									hyprland:dispatch("alterzorder", "top, " .. c:get_address())
								end
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
						label = bind(c, "title"):as(tostring)
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
	local tray_visibility = Variable(false)

	return gtkWidget.Box {
		class_name = "systray",
		gtkWidget.Button {
			class_name = "revealer",
			on_clicked = function()
				tray_visibility:set(not tray_visibility:get())
			end,
			gtkWidget.Icon {
				icon = bind(tray_visibility):as(function(vis)
					return vis and "arrow-right" or "arrow-left"
				end)
			}
		},
		bind(tray, "items"):as(function(items)
			return map(items, function(item)
				return gtkWidget.MenuButton {
					class_name = "item",
					visible = bind(tray_visibility):as(function(vis)
						return vis
					end),
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

return function(gdkmonitor)
	local Anchor = astal.require("Astal").WindowAnchor

	return gtkWidget.Window {
		name = "Bar",
		class_name = "bar",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.TOP + Anchor.LEFT + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		gtkWidget.CenterBox {
			class_name = "mainbox",
			gtkWidget.Box {
				halign = "START",
				Workspaces(),
				Clients()
			},
			gtkWidget.Box {},
			gtkWidget.Box {
				halign = "END",
				SysTray(),
				KbLayout(),
				Time("%A %e - %H:%M")
			}
		}
	}
end
