local astal = require("astal")
local Variable = astal.Variable
local bind = astal.bind
local gtkApp = require("astal.gtk3.app")
local gtkWidget = require("astal.gtk3.widget")
local gtkAstal = require("astal.gtk3").Astal
local gtkGdk = require("astal.gtk3").Gdk
local map = require("lib").map
local AstalApps = astal.require("AstalApps")

local function hide()
	local launcher = gtkApp:get_window("Launcher")
	if launcher then launcher:hide() end
end

local function AppButton(app)
	return gtkWidget.Button {
		class_name = "app-button",
		on_clicked = function()
			hide()
			app:launch()
		end,
		gtkWidget.Box {
			gtkWidget.Label {
				class_name = "name",
				wrap = true,
				xalign = 0,
				label = app.name
			}
		}
	}
end

return function()
	local apps = AstalApps.Apps()

	local app_query = Variable("")
	local app_list = bind(app_query):as(function(text)
		return apps:fuzzy_query(text)
	end)

	local on_enter = function()
		local found = apps:fuzzy_query(app_query:get())[1]
		if found then
			found:launch()
			hide()
		end
	end

	local entry = gtkWidget.Entry {
		placeholder_text = "Search",
		text = bind(app_query):as(function(text)
			return tostring(text)
		end),
		on_changed = function(self)
			app_query:set(self.text)
		end,
		on_activate = on_enter
	}

	local apps_scrollable = gtkWidget.Scrollable {
		min_content_height = 500,
		visible = app_list:as(function(list)
			return #list ~= 0
		end),
		gtkWidget.Box {
			spacing = 6,
			vertical = true,
			app_list:as(function(list)
				return map(list, function(app)
					return AppButton(app)
				end)
			end)
		}
	}

	local not_found = gtkWidget.Box {
		halign = "CENTER",
		class_name = "not-found",
		vertical = true,
		visible = app_list:as(function(list)
			return #list == 0
		end),
		gtkWidget.Icon {
			icon = "system-search-symbolic"
		},
		gtkWidget.Label {
			label = "No match found"
		}
	}

	return gtkWidget.Window {
		name = "Launcher",
		class_name = "launcher",
		anchor = gtkAstal.WindowAnchor.TOP + gtkAstal.WindowAnchor.BOTTOM,
		exclusivity = "IGNORE",
		keymode = "ON_DEMAND",
		application = gtkApp,
		visible = false,
		on_show = function()
			app_query:set("")
		end,
		on_key_press_event = function(self, event)
			if event.keyval == gtkGdk.KEY_Escape then
				self:hide()
			end
		end,
		setup = function(self)
			self:hook(self, "notify::visible", function()
				if self.visible then
					entry:set_position(-1)
					entry:select_region(0, -1)
					entry:grab_focus()
				end
			end)
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
					class_name = "mainbox",
					entry,
					apps_scrollable,
					not_found
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
