local awful = require("awful")
local ruled = require("ruled")

ruled.client.connect_signal("request::rules", function()
	ruled.client.append_rule {
		id = "global",
		rule = {},
		properties = {
			screen = awful.screen.preferred,
			focus = awful.client.focus.filter,
			raise = true,
			size_hints_honor = false,
			placement = function(d)
				awful.placement.centered(d, { honor_workarea = true })
			end,
		}
	}

	ruled.client.append_rule {
		id = "titlebars",
		rule_any = {
			type = { "normal", "dialog" }
		},
		properties = {
			titlebars_enabled = true
		}
	}

	-- User rules
	ruled.client.append_rule {
		rule_any = {
			class = { "steam", "Lunar Client", "CheatBreaker" }
		},
		properties = {
			tag = "tag_3",
			switchtotag = true
		}
	}

	ruled.client.append_rule {
		rule_any = {
			class = { "discord" }
		},
		properties = {
			tag = "tag_4",
			switchtotag = true
		}
	}

	ruled.client.append_rule {
		rule_any = {
			class = { "firefox" }
		},
		properties = {
			tag = "tag_5",
			switchtotag = true
		}
	}

	ruled.client.append_rule {
		rule_any = {
			class = { "Eom", "mpv", "vlc" }
		},
		properties = {
			width = 1300,
			height = 900
		}
	}
end)

client.connect_signal("request::manage", function(c)
	if c.maximized then
		c.x = c.screen.workarea.x
		c.y = c.screen.workarea.y
		c.width = c.screen.workarea.width
		c.height = c.screen.workarea.height
	elseif c.fullscreen then
		c.x = c.screen.geometry.x
		c.y = c.screen.geometry.y
		c.width = c.screen.geometry.width
		c.height = c.screen.geometry.height
	end

	if c.transient_for then
		c.placement = function(d)
			awful.placement.centered(d, { parent = c.transient_for })
			awful.placement.no_offscreen(d)
		end
	end
end)
