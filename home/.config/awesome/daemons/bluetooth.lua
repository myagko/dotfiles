----------------------------------------
-- @author https://github.com/myagko
----------------------------------------

local awful = require("awful")
-- timeout 5 bluetoothctl scan on ; bluetoothctl devices

local Bluetooth_daemon = {}

function Bluetooth_daemon:get_status()
	awful.spawn.easy_async_with_shell("timeout 1 bluetoothctl show", function(stdout)
		local st = stdout:match("Powered:%s+(%w+)")
		if st == "yes" then
			self.status = true
		else
			self.status = false
		end
		awesome.emit_signal("bluetooth:status", self.status)
	end)
end

function Bluetooth_daemon:toggle()
	if not self.status then
		awful.spawn.easy_async_with_shell("bluetoothctl power on", function()
			self:get_status()
		end)
	else
		awful.spawn.easy_async_with_shell("bluetoothctl power off", function()
			self:get_status()
		end)
	end
end

return Bluetooth_daemon
