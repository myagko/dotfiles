local App = require("astal.gtk3").App
local Widget = require("astal.gtk3").Widget
local Astal = require("astal.gtk3").Astal
local Gdk = require("astal.gtk3").Gdk
local Gtk = require("astal.gtk3").Gtk

local NotificationList = require("lua.widgets.notification_list")
local AudioSliders = require("lua.widgets.audio_sliders")

local function hide()
	local panel = App:get_window("Control-panel")
	if panel then panel:hide() end
end

return function()
	local Anchor = Astal.WindowAnchor
	return Widget.Window {
		name = "Control-panel",
		class_name = "control-panel",
		anchor = Anchor.BOTTOM + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		keymode = "ON_DEMAND",
		application = App,
		visible = false,
		on_key_press_event = function(self, event)
			if event.keyval == Gdk.KEY_Escape then
				self:hide()
			end
		end,
		Widget.Box {
			Widget.EventBox {
				width_request = 4000,
				expand = true,
				on_click = hide
			},
			Widget.Box {
				hexpand = false,
				vertical = true,
				Widget.EventBox {
					on_click = hide,
					height_request = 1000
				},
				Widget.Box {
					class_name = "mainbox",
					width_request = 500,
					height_request = 800,
					vertical = true,
					spacing = 8,
					NotificationList(),
					Gtk.Separator {
						visible = true
					},
					AudioSliders()
				}
			}
		}
	}
end
