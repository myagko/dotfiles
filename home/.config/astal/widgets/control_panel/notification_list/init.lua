local astal = require("astal")
local gtkWidget = require("astal.gtk3").Widget
local gtkAstal = require("astal.gtk3").Astal
local gtkGtk = require("astal.gtk3").Gtk
local map = require("lib").map
local time = require("lib").time
local file_exists = require("lib").file_exists
local varmap = require("lib").varmap
local AstalNotifd = astal.require("AstalNotifd")

local notifd = AstalNotifd.get_default()

local function is_icon(icon)
	return gtkAstal.Icon.lookup_icon(icon) ~= nil
end

local function create_notification(props)
	local n = props.notification

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
				ellipsize = "END",
				lines = 6,
				label = n.body
			}
		}
	}

	return gtkWidget.Box {
		class_name = string.format("notification %s", string.lower(n.urgency)),
		setup = props.setup,
		vertical = true,
		header,
		gtkGtk.Separator {
			visible = true
		},
		content,
		#n.actions > 1 and gtkWidget.Box {
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
end

local function create_notification_map()
	local notif_map = varmap({})

	notifd.on_notified = function(_, id)
		local n = notifd:get_notification(id)

		notif_map.set(id, create_notification {
			notification = n
		})
	end

	notifd.on_resolved = function(_, id)
		notif_map.delete(id)
	end

	return notif_map
end

return function ()
	local notifs = create_notification_map()

	return gtkWidget.Scrollable {
		min_content_height = 600,
		gtkWidget.Box {
			vertical = true,
			notifs()
		}
	}
end
