local astal = require("astal")
local gtkWidget = require("astal.gtk3").Widget
local Gtk = require("astal.gtk3").Gtk
local gtkAstal = require("astal.gtk3").Astal
local AstalNotifd = astal.require("AstalNotifd")
local timeout = astal.timeout

local map = require("lib").map
local time = require("lib").time
local file_exists = require("lib").file_exists
local varmap = require("lib").varmap
local notifd = AstalNotifd.get_default()

local TIMEOUT_DELAY = 5000

local function is_icon(icon)
	return gtkAstal.Icon.lookup_icon(icon) ~= nil
end

---@param props { setup?: function, notification: any }
local function create_notification(props)
	local n = props.notification

	local header = gtkWidget.Box {
		class_name = "header",
		(n.app_icon or n.desktop_entry) and gtkWidget.Icon {
			class_name = "app-icon",
			icon = n.app_icon or n.desktop_entry
		},
		gtkWidget.Label {
			class_name = "app-name",
			halign = "START",
			ellipsize = "END",
			label = n.app_name or "Unknown"
		},
		gtkWidget.Label {
			class_name = "time",
			hexpand = true,
			halign = "END",
			label = time(n.time)
		},
		gtkWidget.Button {
			on_clicked = function()
				n:dismiss()
			end,
			gtkWidget.Icon {
				icon = "window-close-symbolic"
			}
		}
	}

	local content = gtkWidget.Box {
		class_name = "content",
		(n.image and file_exists(n.image)) and gtkWidget.Box {
			valign = "START",
			class_name = "image",
			css = string.format("background-image: url('%s')", n.image)
		},
		n.image and is_icon(n.image) and gtkWidget.Box {
			valign = "START",
			class_name = "icon-image",
			gtkWidget.Icon {
				icon = n.image,
				hexpand = true,
				vexpand = true,
				halign = "CENTER",
				valign = "CENTER"
			}
		},
		gtkWidget.Box {
			vertical = true,
			gtkWidget.Label {
				class_name = "summary",
				halign = "START",
				xalign = 0,
				ellipsize = "END",
				label = n.summary
			},
			gtkWidget.Label {
				class_name = "body",
				wrap = true,
				use_markup = true,
				halign = "START",
				xalign = 0,
				justify = "FILL",
				label = n.body
			}
		}
	}

	return gtkWidget.EventBox {
		class_name = string.format("Notification %s", string.lower(n.urgency)),
		setup = props.setup,
		gtkWidget.Box {
			vertical = true,
			header,
			Gtk.Separator {
				visible = true
			},
			content,
			#n.actions > 0 and gtkWidget.Box {
				class_name = "actions",
				map(n.actions, function(action)
					return gtkWidget.Button {
						hexpand = true,
						on_clicked = function()
							return n:invoke(action.id)
						end,
						gtkWidget.Label {
							label = action.label,
							halign = "CENTER",
							hexpand = true
						}
					}
				end)
			}
		}
	}
end

local function create_notification_map()
	local notif_map = varmap({})

	notifd.on_notified = function(_, id)
		notif_map.set(id, create_notification {
			notification = notifd:get_notification(id),
			setup = function()
				timeout(TIMEOUT_DELAY, function()
					notif_map.delete(id)
				end)
			end
		})
	end

	notifd.on_resolved = function(_, id)
		notif_map.delete(id)
	end

	return notif_map
end

return function(gdkmonitor)
	local Anchor = astal.require("Astal").WindowAnchor
	local notifs = create_notification_map()

	return gtkWidget.Window {
		class_name = "Notifications",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.TOP + Anchor.RIGHT,
		gtkWidget.Box {
			vertical = true,
			notifs()
		}
	}
end
