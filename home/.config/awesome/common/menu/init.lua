local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local capi = { mouse = mouse }
local dpi = beautiful.xresources.apply_dpi

local menu = {}

local function update_items(self)
	local wp = self._private
	local theme = wp.theme
	local items_layout = self.widget:get_children_by_id("items-layout")[1]
	for i, item in ipairs(items_layout.children) do
		if wp.select_index and i == wp.select_index then
			item:set_bg(theme.item_hover_bg)
			item:set_fg(theme.item_hover_fg)
		else
			item:set_bg(theme.item_bg)
			item:set_fg(theme.item_fg)
		end
	end
end

local function on_enter(self, index, args)
	if not index or not args then return end
	local wp = self._private

	wp.select_index = index
	update_items(self)

	if args.items then
		if not wp.children[index] then
			wp.children[index] = self.new(args, self)
		end

		if wp.active_child and wp.active_child ~= wp.children[index] then
			wp.active_child:hide()
		end

		wp.active_child = wp.children[index]

		if not wp.active_child.visible then
			wp.active_child:show()
		end
	else
		if wp.active_child then
			wp.active_child:destroy()
		end
	end
end

local function run_keygrabber(self)
	local wp = self._private
	wp.keygrabber = awful.keygrabber.run(function(_, key, event)
		if event ~= "press" then return end
		if gtable.hasitem(wp.keys.up, key) then
			self:back()
			update_items(self)
		elseif gtable.hasitem(wp.keys.down, key) then
			self:next()
			update_items(self)
		elseif gtable.hasitem(wp.keys.left, key) then
			self:hide()
		elseif gtable.hasitem(wp.keys.right, key) then
			on_enter(self, wp.select_index, wp.opts[wp.select_index])
		elseif gtable.hasitem(wp.keys.exec, key) then
			on_enter(self, wp.select_index, wp.opts[wp.select_index])
		elseif gtable.hasitem(wp.keys.close, key) then
			self:get_root():hide()
		end
	end)
end

local function entry(self, index, args)
	local wp = self._private
	local theme = wp.theme

	local ret = wibox.widget {
		widget = wibox.container.background,
		shape = theme.item_shape,
		{
			id = "item-content",
			widget = wibox.container.margin,
			margins = theme.item_margins
		}
	}

	local item_content = ret:get_children_by_id("item-content")[1]

	if args.items then
		item_content:set_widget({
			widget = wibox.widget.textbox,
			font = theme.item_font,
			markup = args.label .. " " .. ">"
		})
	else
		item_content:set_widget({
			widget = wibox.widget.textbox,
			font = theme.item_font,
			markup = args.label
		})
	end

	ret:connect_signal("mouse::enter", function()
		on_enter(self, index, args)
	end)

	return ret
end

function menu:next()
	local wp = self._private
	local items_layout = self.widget:get_children_by_id("items-layout")[1]
	if not wp.select_index then
		wp.select_index = 1
	elseif wp.select_index ~= #items_layout.children then
		wp.select_index = wp.select_index + 1
	else
		wp.select_index = 1
	end
end

function menu:back()
	local wp = self._private
	local items_layout = self.widget:get_children_by_id("items-layout")[1]
	if not wp.select_index then
		wp.select_index = 1
	elseif wp.select_index ~= 1 then
		wp.select_index = wp.select_index - 1
	else
		wp.select_index = #items_layout.children
	end
end

function menu:hide()
	local wp = self._private
	if not wp.state then return end
	wp.state = false
	awful.keygrabber.stop(wp.keygrabber)
	wp.select_index = nil
	self:destroy_active_children()
	self.visible = false
end

function menu:show()
	local wp = self._private
	if wp.state then return end
	wp.state = true
	update_items(self)
	self.screen = capi.mouse.screen
	local m_coords = capi.mouse.coords()
	if not wp.parent then
		self.x = m_coords.x
		self.y = m_coords.y
	else
		local parent_p = wp.parent._private
		local parent_items_layout = wp.parent.widget:get_children_by_id("items-layout")[1]
		self.x = wp.parent.x + wp.parent.width + wp.theme.placement_margin
		self.y = wp.parent.y +
			(wp.parent.height - wp.theme.margins * 2) /
			#parent_items_layout.children *
			(parent_p.select_index - 1)
	end
	run_keygrabber(self)
	self.visible = true
end

function menu:toggle()
	if not self.visible then
		self:show()
	else
		self:hide()
	end
end

function menu:get_root()
	local wp = self._private
	return wp.parent and menu.get_root(wp.parent) or self
end

function menu:destroy_active_children()
	local child = self._private.active_child
	while child do
		local parent = child
		child = child._private.active_child
		parent:destroy()
	end
end

function menu:destroy()
	self:hide()
	self = nil
end

function menu.new(args, parent)
	if not args then return end

	local theme = setmetatable(args.theme or {}, {
		__index = {
			placement_margin = dpi(3),
			bg = beautiful.bg,
			fg = beautiful.fg,
			border_color = beautiful.border_color_normal,
			border_width = beautiful.border_width,
			shape = beautiful.rrect(dpi(8)),
			margins = dpi(5),
			item_bg = beautiful.bg,
			item_fg = beautiful.fg,
			item_hover_bg = beautiful.ac,
			item_hover_fg = beautiful.bg,
			item_shape = beautiful.rrect(dpi(5)),
			item_margins = dpi(5),
			item_font = beautiful.font
		}
	})

	local ret = awful.popup {
		visible = false,
		ontop = true,
		type = "popup_menu",
		bg = "#00000000",
		widget = {
			widget = wibox.container.background,
			bg = theme.bg,
			fg = theme.fg,
			border_color = theme.border_color,
			border_width = theme.border_width,
			shape = theme.shape,
			{
				widget = wibox.container.margin,
				margins = theme.margins,
				{
					id = "items-layout",
					layout = wibox.layout.fixed.vertical
				}
			}
		}
	}

	gtable.crush(ret, menu, true)
	local wp = ret._private

	wp.keys = {
		up = { "Up" },
		down = { "Down" },
		left = { "Left" },
		right = { "Right" },
		exec = { "Return" },
		close = { "Escape" }
	}

	wp.opts = args.items
	wp.theme = theme
	wp.parent = parent
	wp.children = {}

	local items_layout = ret.widget:get_children_by_id("items-layout")[1]
	if wp.opts then
		for index, item in ipairs(wp.opts) do
			item.theme = theme
			items_layout:add(entry(ret, index, item))
		end
	end

	return ret
end

return setmetatable({
	new = menu.new
}, {
	__call = function(_, ...)
		return menu.new(...)
	end
})
