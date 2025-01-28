local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gobject = require("gears.object")
local gtable = require("gears.table")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local powermenu = {}
local instance = nil

function powermenu:next()
	if self.index_element ~= #self.elements then
		self.index_element = self.index_element + 1
	else
		self.index_element = 1
	end
end

function powermenu:back()
	if self.index_element ~= 1 then
		self.index_element = self.index_element - 1
	else
		self.index_element = #self.elements
	end
end

function powermenu:update_elements()
	self.elements_container:reset()

	for i, element in ipairs(self.elements) do
		local element_widget = wibox.widget {
			widget = wibox.container.background,
			forced_width = dpi(120),
			forced_height = dpi(120),
			buttons = {
				awful.button({}, 1, function()
					if self.index_element == i then
						element.exec()
					else
						self.index_element = i
						self:update_elements()
					end
				end)
			},
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = beautiful.font_h3,
				markup = element.icon
			}
		}

		if i == self.index_element then
			element_widget.bg = element.color
			element_widget.fg = beautiful.bg
		end

		element_widget:connect_signal("mouse::enter", function(w)
			if not (i == self.index_element) then
				w.bg = beautiful.bg_urg
			end
		end)

		element_widget:connect_signal("mouse::leave", function(w)
			if not (i == self.index_element) then
				w.bg = beautiful.bg
			end
		end)

		self.elements_container:add(element_widget)
	end
end

function powermenu:open()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:emit_signal("state", self.state)
	self.index_element = 1
	self:update_elements()
	self:run_keygrabber()
end

function powermenu:close()
	if not self.state then return end
	self.state = false
	self:stop_keygrabber()
	self.popup_widget.visible = false
	self:emit_signal("state", self.state)
end

function powermenu:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

function powermenu:run_keygrabber()
	self.keygrabber = awful.keygrabber.run(function(_, key, event)
		if event ~= "press" then return end
		if gtable.hasitem(self.keys.up, key) then
			self:next()
		elseif gtable.hasitem(self.keys.down, key) then
			self:back()
		elseif gtable.hasitem(self.keys.left, key) then
			self:back()
		elseif gtable.hasitem(self.keys.right, key) then
			self:next()
		elseif gtable.hasitem(self.keys.exec, key) then
			self.elements[self.index_element]:exec()
		elseif gtable.hasitem(self.keys.close, key) then
			self:close()
		end
		self:update_elements()
	end)
end

function powermenu:stop_keygrabber()
	awful.keygrabber.stop(self.keygrabber)
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, powermenu, true)

	ret.keys = {
		up = { "Up" },
		down = { "Down" },
		left = { "Left" },
		right = { "Right" },
		exec = { "Return" },
		close = { "Escape" }
	}

	ret.elements = {
		{
			exec = function()
				awful.spawn("poweroff")
			end,
			icon = text_icons.poweroff,
			color = beautiful.red
		},
		{
			exec = function()
				awful.spawn("reboot")
			end,
			icon = text_icons.reboot,
			color = beautiful.yellow
		},
		{
			exec = function()
				awesome.quit()
			end,
			icon = text_icons.exit,
			color = beautiful.green
		}
	}

	ret.elements_container = wibox.widget {
		layout = wibox.layout.fixed.horizontal
	}

	ret.main_widget = wibox.widget {
		widget = wibox.container.background,
		bg = beautiful.bg,
		forced_width = dpi(120)*3 + dpi(10)*3,
		forced_height = dpi(120) + dpi(10)*3,
		{
			widget = wibox.container.margin,
			margins = dpi(10)*1.5,
			ret.elements_container
		}
	}

	ret.popup_widget = awful.popup {
		visible = false,
		ontop = true,
		screen = screen.primary,
		border_width = beautiful.border_width,
		border_color = beautiful.border_color,
		placement = function(d)
			awful.placement.centered(d, {
				honor_workarea = true
			})
		end,
		widget = ret.main_widget
	}

	return ret
end

if not instance then
	instance = new()
end

return instance
