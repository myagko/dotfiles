local gtkWidget = require("astal.gtk3").Widget
local gtkApp = require("astal.gtk3").App
local gtkAstal = require("astal.gtk3").Astal
local gtkGdk = require("astal.gtk3").Gdk
local gtkGtk = require("astal.gtk3").Gtk

local NotificationList = require("lua.widgets.control_panel.notification_list")
local AudioSliders = require("lua.widgets.control_panel.audio_sliders")

local function hide()
	local panel = gtkApp:get_window("Control-panel")
	if panel then panel:hide() end
end

return function()
	return gtkWidget.Window {
		name = "Control-panel",
		class_name = "control-panel",
		anchor = gtkAstal.WindowAnchor.BOTTOM + gtkAstal.WindowAnchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		keymode = "ON_DEMAND",
		application = gtkApp,
		visible = false,
		on_key_press_event = function(self, event)
			if event.keyval == gtkGdk.KEY_Escape then
				self:hide()
			end
		end,
		gtkWidget.Box {
			gtkWidget.EventBox {
				width_request = 4000,
				expand = true,
				on_click = hide
			},
			gtkWidget.Box {
				hexpand = false,
				vertical = true,
				gtkWidget.EventBox {
					on_click = hide,
					height_request = 1000
				},
				gtkWidget.Box {
					class_name = "mainbox",
					width_request = 500,
					height_request = 800,
					vertical = true,
					spacing = 8,
					NotificationList(),
					gtkGtk.Separator {
						visible = true
					},
					AudioSliders()
				}
			}
		}
	}
end
