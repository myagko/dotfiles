local gtkWidget = require("astal.gtk3").Widget
local gtkApp = require("astal.gtk3").App
local gtkAstal = require("astal.gtk3").Astal
local gtkGdk = require("astal.gtk3").Gdk

local NotificationList = require("widgets.control_panel.notification_list")

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
					vertical = true,
					width_request = 500,
					height_request = 800,
					class_name = "mainbox",
					NotificationList()
				}
			}
		}
	}
end
