local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi
local text_icons = beautiful.text_icons

local powermenu = {}

powermenu.elements = {
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

powermenu.main_widget = wibox.widget {
	widget = wibox.container.background,
	bg = beautiful.background,
	forced_width = dpi(120)*3 + dpi(10)*5,
	forced_height = dpi(120) + dpi(10)*3,
	{
		widget = wibox.container.margin,
		margins = dpi(10)*1.5,
		{
			layout = wibox.layout.fixed.vertical,
			{
				id = "prompt",
				widget = wibox.widget.textbox,
				visible = false
			},
			{
				id = "elements_container",
				layout = wibox.layout.fixed.horizontal,
				spacing = dpi(10)
			}
		}
	}
}

powermenu.popup_widget = awful.popup {
	visible = false,
	ontop = true,
	screen = screen.primary,
	widget = {
		widget = wibox.container.background,
		bg = beautiful.background_urgent,
		{
			widget = wibox.container.margin,
			margins = beautiful.border_width,
			{
				widget = wibox.container.background,
				bg = beautiful.background,
				powermenu.main_widget
			}
		}
	}
}

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

function powermenu:add_elements()
	local elements_container = self.main_widget:get_children_by_id("elements_container")[1]
	elements_container:reset()

	for i, element in ipairs(self.elements) do
		local element_widget = wibox.widget {
			widget = wibox.container.background,
			forced_width = dpi(120),
			forced_height = dpi(120),
			buttons = {
				awful.button({}, 1, function()
					if self.index_element == i then
						element:exec()
					else
						self.index_element = i
						self:add_elements()
					end
				end)
			},
			{
				widget = wibox.widget.textbox,
				align = "center",
				font = helpers.ui.font(beautiful.font_size + dpi(15)),
				text = element.icon
			}
		}

		if i == self.index_element then
			element_widget.bg = element.color
			element_widget.fg = beautiful.background
		end

		elements_container:add(element_widget)
	end

	collectgarbage("collect")
end

function powermenu:open()
	if self.state then return end
	self.state = true
	self.popup_widget.visible = true
	self:send_state()

	self.index_element = 1
	self:add_elements()

	awful.keygrabber.stop()
	local prompt = self.main_widget:get_children_by_id("prompt")[1]

	awful.prompt.run {
		textbox = prompt,
		exe_callback = function()
			self.elements[self.index_element]:exec()
		end,
		changed_callback = function()
			self:add_elements()
		end,
		keypressed_callback = function(_, key)
			if key == "Right" or key == "Down" then
				self:next()
			elseif key == "Left" or key == "Up" then
				self:back()
			end
		end,
		done_callback = function()
			self:close()
		end
	}

	self.popup_widget.placement = function(d)
		awful.placement.centered(d, { honor_workarea = true })
	end
end

function powermenu:close()
	if not self.state then return end
	self.state = false
	awful.keygrabber.stop()
	self.popup_widget.visible = false
	self:send_state()
end

function powermenu:toggle()
	if not self.popup_widget.visible then
		self:open()
	else
		self:close()
	end
end

function powermenu:send_state()
	awesome.emit_signal("powermenu:state", self.state)
end

return powermenu
