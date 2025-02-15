local astal = require("astal")
local Variable = astal.Variable
local bind = astal.bind
local GLib = astal.require("GLib")
local gtkWidget = require("astal.gtk3.widget")
local Tray = astal.require("AstalTray")
local Hyprland = astal.require("AstalHyprland")
local map = require("lib").map

local hypr = Hyprland.get_default()
local tray = Tray.get_default()

local function Workspaces()
	return gtkWidget.Box {
		class_name = "Workspaces",
		bind(hypr, "workspaces"):as(function(wss)
			table.sort(wss, function(a, b) return a.id < b.id end)
			return map(wss, function(ws)
				if not (ws.id >= -99 and ws.id <= -2) then
					return gtkWidget.Button {
						class_name = bind(hypr, "focused-workspace"):as(function(fw)
							return fw == ws and "focused" or ""
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
		class_name = "Clients",
		spacing = 5,
		bind(hypr, "clients"):as(function(cs)
			return map(cs, function(c)
				return gtkWidget.Button {
					setup = function(self)
						self:hook(c, "moved-to", function(ws)
							self:set_visible(ws == hypr:get_focused_workspace())
						end)
					end,
					visible = bind(hypr, "focused-workspace"):as(function(fw)
						return fw == c:get_workspace()
					end),
					on_clicked = function()
						if c ~= hypr:get_focused_client() then
							c:focus()
						end
					end,
					gtkWidget.Label {
						label = bind(c, "title"):as(tostring)
					}
				}
			end)
		end)
	}
end

local function SysTray()
	return gtkWidget.Box {
		class_name = "SysTray",
		bind(tray, "items"):as(function(items)
			return map(items, function(item)
				return gtkWidget.MenuButton {
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

	return gtkWidget.Label {
		class_name = "Time",
		on_destroy = function()
			time:drop()
		end,
		label = time(),
	}
end

return function(gdkmonitor)
	local Anchor = astal.require("Astal").WindowAnchor

	return gtkWidget.Window {
		class_name = "Bar",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.TOP + Anchor.LEFT + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		gtkWidget.CenterBox {
			class_name = "bar-centerbox",
			gtkWidget.Box {
				halign = "START",
				Workspaces()
			},
			gtkWidget.Box {
				Clients()
			},
			gtkWidget.Box {
				halign = "END",
				SysTray(),
				Time("%A %e - %H:%M")
			}
		}
	}
end
