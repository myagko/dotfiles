local awful = require("awful")

awful.screen.connect_for_each_screen(function(s)
	awful.tag({ "tag_1", "tag_2", "tag_3", "tag_4", "tag_5" }, s, awful.layout.layouts[1])
end)

tag.connect_signal("request::default_layouts", function()
	awful.layout.append_default_layouts {
		awful.layout.suit.floating,
		awful.layout.suit.tile,
	}
end)
