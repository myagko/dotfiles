local awful = require("awful")
local beautiful = require("beautiful")
local ruled = require("ruled")
local naughty = require("naughty")
local User = require("user")

beautiful.init("~/.config/awesome/themes/" .. User.theme .. "/theme.lua")

tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts({
		awful.layout.suit.floating,
		--awful.layout.suit.tile
	})
end)

awful.screen.connect_for_each_screen(function(s)
	awful.tag({ "1", "2", "3", "4" }, s, awful.layout.layouts[1])
end)

local Bar = require("ui.bar")
local Walls = require("ui.walls")
local Notifications = require("ui.notifications")
local Titlebars = require("ui.titlebars")

awful.screen.connect_for_each_screen(function(s)
	Bar:create_main(s)
end)

screen.connect_signal("request::wallpaper", function(s)
	Walls:create(s)
end)

ruled.notification.connect_signal('request::rules', function()
	Notifications:append_rules()
end)

naughty.connect_signal("request::display", function(n)
	Notifications:display(n)
end)

client.connect_signal("request::titlebars", function(c)
	Titlebars:create(c)
end)

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
				awful.placement.centered(d)
			end,
		}
	}

	ruled.client.append_rule {
		id = "titlebars",
		rule_any = { type = { "normal", "dialog" } },
		except_any = { class = { "steam", "launcher" } },
		properties = { titlebars_enabled = true }
	}

	ruled.client.append_rule {
		rule_any = { class = { "firefox" } },
		properties = { tag = "4", switchtotag = true }
	}

	ruled.client.append_rule {
		rule_any = { class = { "mpv" } },
		properties = { width = 1080, height = 720 }
	}

	ruled.client.append_rule {
		rule_any = { class = { "steam", "discord", "launcher" } },
		properties = {
			tag = "3", switchtotag = true,
			placement = function(d)
				awful.placement.centered(d, { honor_workarea = true })
			end
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
