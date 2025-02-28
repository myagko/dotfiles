local astal = require("astal")
local timeout = astal.timeout
local AstalNotifd = astal.require("AstalNotifd")
local Widget = require("astal.gtk3").Widget
local Astal = require("astal.gtk3").Astal
local varmap = require("lua.lib").varmap

local Notification = require("lua.widgets.notification")
local notifd = AstalNotifd.get_default()
local TIMEOUT_DELAY = 5000

return function(gdkmonitor)
	local notif_map = varmap({})

	notifd.on_notified = function(_, id)
		notif_map.set(id, Notification(notifd:get_notification(id), function()
			timeout(TIMEOUT_DELAY, function()
				notif_map.delete(id)
			end)
		end))
	end

	notifd.on_resolved = function(_, id)
		notif_map.delete(id)
	end

	local Anchor = Astal.WindowAnchor
	return Widget.Window {
		name = "Notifications",
		class_name = "notifications",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.TOP + Anchor.RIGHT,
		Widget.Box {
			vertical = true,
			notif_map()
		}
	}
end
