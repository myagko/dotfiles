local astal = require("astal")
local Variable = astal.Variable
local AstalNotifd = astal.require("AstalNotifd")
local Widget = require("astal.gtk3").Widget
local varmap = require("lua.lib").varmap

local Notification = require("lua.widgets.notifications.notification")

return function()
	local notifd = AstalNotifd.get_default()
	local notif_map = varmap({})
	local notif_count = Variable(#notifd:get_notifications())

	for _, n in ipairs(notifd:get_notifications()) do
		notif_map.set(n:get_id(), Notification(n))
	end

	notifd.on_notified = function(_, id)
		notif_map.set(id, Notification(notifd:get_notification(id)))
		notif_count:set(#notifd:get_notifications())
	end

	notifd.on_resolved = function(_, id)
		notif_map.delete(id)
		notif_count:set(#notifd:get_notifications())
	end

	return Widget.Box {
		class_name = "notification-list",
		vertical = true,
		spacing = 8,
		Widget.Box {
			class_name = "header",
			Widget.Label {
				class_name = "title",
				label = notif_count():as(function(count)
					return "Notifications " ..
						(count > 0 and "(" .. tostring(count) .. ")" or "")
				end)
			},
			Widget.Box {
				hexpand = true,
				halign = "END",
				Widget.Button {
					class_name = "clear-button",
					on_clicked = function()
						for _, n in ipairs(notifd:get_notifications()) do
							n:dismiss()
						end
					end,
					Widget.Icon {
						icon = "trash-symbolic"
					}
				}
			}
		},
		Widget.Scrollable {
			vexpand = true,
			Widget.Box {
				vertical = true,
				spacing = 8,
				notif_map(),
				Widget.Box {
					class_name = "empty-massage",
					expand = true,
					halign = "CENTER",
					valign = "CENTER",
					visible = notif_map():as(function(v)
						return #v == 0
					end),
					Widget.Label {
						label = "No notifications"
					}
				}
			}
		}
	}
end
