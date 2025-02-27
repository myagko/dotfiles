local astal = require("astal")
local timeout = astal.timeout
local AstalNotifd = astal.require("AstalNotifd")
local gtkWidget = require("astal.gtk3").Widget
local gtkAstal = require("astal.gtk3").Astal
local gtkGtk = require("astal.gtk3").Gtk
local map = require("lua.lib").map
local time = require("lua.lib").time
local file_exists = require("lua.lib").file_exists
local varmap = require("lua.lib").varmap
local text_icons = require("lua.text_icons")

local notifd = AstalNotifd.get_default()
local TIMEOUT_DELAY = 5000

local function is_icon(icon)
	return gtkAstal.Icon.lookup_icon(icon) ~= nil
end

local function create_notification(n, setup)
	local header = gtkWidget.Box {
		class_name = "header",
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
			class_name = "dismiss-button",
			on_clicked = function()
				n:dismiss()
			end,
			gtkWidget.Label {
				label = text_icons.cross
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
				ellipsize = "END",
				xalign = 0,
				label = n.summary
			},
			gtkWidget.Label {
				class_name = "body",
				halign = "START",
				wrap = true,
				wrap_mode = "CHAR",
				ellipsize = "END",
				justify = "FILL",
				use_markup = true,
				xalign = 0,
				lines = 4,
				label = n.body
			}
		}
	}

	return gtkWidget.EventBox {
		class_name = string.format("notification %s", string.lower(n.urgency)),
		setup = setup,
		gtkWidget.Box {
			vertical = true,
			expand = true,
			header,
			gtkGtk.Separator {
				visible = true
			},
			content,
			#n.actions > 1 and gtkWidget.Box {
				class_name = "actions",
				map(n.actions, function(action)
					return gtkWidget.Button {
						class_name = "action-button",
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

return function(gdkmonitor)
	local notif_map = varmap({})

	notifd.on_notified = function(_, id)
		notif_map.set(id, create_notification(notifd:get_notification(id), function()
			timeout(TIMEOUT_DELAY, function()
				notif_map.delete(id)
			end)
		end))
	end

	notifd.on_resolved = function(_, id)
		notif_map.delete(id)
	end

	local Anchor = gtkAstal.WindowAnchor
	return gtkWidget.Window {
		name = "Notifications",
		class_name = "notifications",
		gdkmonitor = gdkmonitor,
		anchor = Anchor.TOP + Anchor.RIGHT,
		exclusivity = "EXCLUSIVE",
		gtkWidget.Box {
			vertical = true,
			notif_map()
		}
	}
end
