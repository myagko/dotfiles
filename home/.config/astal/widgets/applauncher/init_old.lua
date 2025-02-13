local astal = require("astal")
local gtkApp = require("astal.gtk3.app")
local gtkWidget = require("astal.gtk3.widget")
local gtkAstal = require("astal.gtk3").Astal
local Gdk = require("astal.gtk3").Gdk
local Variable = astal.Variable
local AstalApps = astal.require("AstalApps")

local slice = require("lib").slice
local map = require("lib").map

local MAX_ITEMS = 7

local function hide()
	local launcher = gtkApp:get_window("launcher")
	if launcher then launcher:hide() end
end

local function AppButton(app)
	return gtkWidget.Button {
		class_name = "AppButton",
		on_clicked = function()
			hide()
			app:launch()
		end,
		gtkWidget.Box {
			gtkWidget.Icon {
				icon = app.icon_name
			},
			gtkWidget.Box {
				valign = "CENTER",
				vertical = true,
				gtkWidget.Label {
					class_name = "name",
					wrap = true,
					xalign = 0,
					label = app.name
				},
				app.description and gtkWidget.Label {
					class_name = "description",
					wrap = true,
					xalign = 0,
					label = app.description
				}
			}
		}
	}
end

return function()
	local apps = AstalApps.Apps()

	local text = Variable("")
	local list = text(function(str)
		return slice(apps:fuzzy_query(str), 1, MAX_ITEMS)
	end)

	local on_enter = function()
		local found = apps:fuzzy_query(text:get())[1]
		if found then
			found:launch()
			hide()
		end
	end

	return gtkWidget.Window {
		name = "launcher",
		anchor = gtkAstal.WindowAnchor.TOP + gtkAstal.WindowAnchor.BOTTOM,
		exclusivity = "IGNORE",
		keymode = "ON_DEMAND",
		application = gtkApp,
		visible = false,
		on_show = function()
			text:set("")
		end,
		on_key_press_event = function(self, event)
			if event.keyval == Gdk.KEY_Escape then self:hide() end
		end,
		gtkWidget.Box {
			gtkWidget.EventBox {
				expand = true,
				on_click = hide,
				width_request = 4000,
			},
			gtkWidget.Box {
				hexpand = false,
				vertical = true,
				gtkWidget.EventBox {
					on_click = hide,
					height_request = 100
				},
				gtkWidget.Box {
					vertical = true,
					width_request = 500,
					class_name = "Applauncher",
					gtkWidget.Entry {
						placeholder_text = "Search",
						text = text(),
						on_changed = function(self)
							text:set(self.text)
						end,
						on_activate = on_enter,
					},
					gtkWidget.Box {
						spacing = 6,
						vertical = true,
						list:as(function(l)
							return map(l, AppButton)
						end)
					},
					gtkWidget.Box {
						halign = "CENTER",
						class_name = "not-found",
						vertical = true,
						visible = list:as(function(l)
							return #l == 0
						end),
						gtkWidget.Icon {
							icon = "system-search-symbolic"
						},
						gtkWidget.Label {
							label = "No match found"
						}
					}
				},
				gtkWidget.EventBox {
					expand = true,
					on_click = hide
				}
			},
			gtkWidget.EventBox {
				width_request = 4000,
				expand = true,
				on_click = hide
			}
		}
	}
end
