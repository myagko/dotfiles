local astal = require("astal")
local Variable = astal.Variable
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

local function is_icon(icon)
	return gtkAstal.Icon.lookup_icon(icon) ~= nil
end

local function create_notification(n)
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

	return gtkWidget.Box {
		class_name = string.format("notification %s", string.lower(n.urgency)),
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
end

return function()
	local notif_map = varmap({})
	local notif_count = Variable(#notifd:get_notifications())

	for _, n in ipairs(notifd:get_notifications()) do
		notif_map.set(n:get_id(), create_notification(n))
	end

	notifd.on_notified = function(_, id)
		notif_map.set(id, create_notification(notifd:get_notification(id)))
		notif_count:set(#notifd:get_notifications())
	end

	notifd.on_resolved = function(_, id)
		notif_map.delete(id)
		notif_count:set(#notifd:get_notifications())
	end

	return gtkWidget.Box {
		class_name = "notification-list",
		vertical = true,
		spacing = 8,
		gtkWidget.Box {
			class_name = "header",
			gtkWidget.Label {
				class_name = "title",
				label = notif_count():as(function(count)
					return "Notifications " ..
						(count > 0 and "(" .. tostring(count) .. ")" or "")
				end)
			},
			gtkWidget.Box {
				hexpand = true,
				halign = "END",
				gtkWidget.Button {
					class_name = "clear-button",
					on_clicked = function()
						for _, n in ipairs(notifd:get_notifications()) do
							n:dismiss()
						end
					end,
					gtkWidget.Label {
						label = text_icons.trash
					}
				}
			}
		},
		gtkWidget.Scrollable {
			vexpand = true,
			gtkWidget.Box {
				vertical = true,
				spacing = 8,
				notif_map(),
				gtkWidget.Box {
					class_name = "empty-massage",
					expand = true,
					halign = "CENTER",
					valign = "CENTER",
					visible = notif_map():as(function(v)
						return #v == 0
					end),
					gtkWidget.Label {
						label = "No notifications"
					}
				}
			}
		}
	}
end
