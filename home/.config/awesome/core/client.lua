local awful = require("awful")
local rclient = require("ruled.client")
local capi = { client = client }
--local beautiful = require("beautiful")
--local dpi = beautiful.xresources.apply_dpi

require("awful.autofocus")

capi.client.connect_signal("request::manage", function(c)
	if c.fullscreen then
		c:set_x(c.screen.geometry.x)
		c:set_y(c.screen.geometry.y)
		c:set_width(c.screen.geometry.width)
		c:set_height(c.screen.geometry.height)
	elseif c.maximized then
		c:set_x(c.screen.workarea.x)
		c:set_y(c.screen.workarea.y)
		c:set_width(c.screen.workarea.width)
		c:set_height(c.screen.workarea.height)
	end

	if c.transient_for then
		c.placement = function(d)
			awful.placement.centered(d, { parent = c.transient_for })
			awful.placement.no_offscreen(d)
		end
	end

	--[[
	local cshape = beautiful.rrect(dpi(15))

	c:connect_signal("property::maximized", function()
		c:set_shape(not (c.maximized or c.fullscreen) and cshape or nil)
	end)

	c:connect_signal("property::fullscreen", function()
		c:set_shape(not (c.fullscreen or c.maximized) and cshape or nil)
	end)

	c:set_shape(not (c.maximized or c.fullscreen) and cshape or nil)
	]]
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
			titlebars_enabled = false
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

	rclient.append_rule {
		rule_any = {
			class = { "mpv" }
		},
		properties = {
			width = 1280,
			height = 720
		}
	}
end)
