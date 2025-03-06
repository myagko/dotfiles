local awful = require("awful")
local rclient = require("ruled.client")
local capi = { client = client }

require("awful.autofocus")

capi.client.connect_signal("request::manage", function(c)
	if c.fullscreen then
		c.x = c.screen.geometry.x
		c.y = c.screen.geometry.y
		c.width = c.screen.geometry.width
		c.height = c.screen.geometry.height
	elseif c.maximized then
		c.x = c.screen.workarea.x
		c.y = c.screen.workarea.y
		c.width = c.screen.workarea.width
		c.height = c.screen.workarea.height
	end

	if c.transient_for then
		c.placement = function(d)
			awful.placement.centered(d, { parent = c.transient_for })
			awful.placement.no_offscreen(d)
		end
	end
end)

rclient.connect_signal("request::rules", function()
	rclient.append_rule {
		id = "global",
		rule = {},
		properties = {
			screen = awful.screen.preferred,
			focus = awful.client.focus.filter,
			raise = true,
			size_hints_honor = false,
			placement = function(d)
				awful.placement.centered(d, { honor_workarea = true })
				awful.placement.no_offscreen(d)
			end,
		}
	}

	rclient.append_rule {
		id = "titlebars",
		rule_any = {
			type = { "normal", "dialog" }
		},
		properties = {
			titlebars_enabled = true
		}
	}

	rclient.append_rule {
		rule_any = {
			class = { "steam", "lunarclient", "CheatBreaker" }
		},
		properties = {
			tag = "tag_3"
		}
	}

	rclient.append_rule {
		rule_any = {
			class = { "vesktop", "discord" }
		},
		properties = {
			tag = "tag_4"
		}
	}

	rclient.append_rule {
		rule_any = {
			class = { "firefox" }
		},
		properties = {
			tag = "tag_5"
		}
	}
end)
