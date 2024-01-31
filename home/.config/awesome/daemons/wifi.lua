local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local Wifi_daemon = {}

function Wifi_daemon:get_status()
	awful.spawn.easy_async_with_shell("nmcli g | sed 1d | awk '{print $4}'", function(stdout)
		local rd = stdout:match("(%w+)")
		if rd == "enabled" then
			self.status = true
			self:scan()
		else
			self.status = false
		end
		awesome.emit_signal("wifi:status", self.status)
	end)
end

function Wifi_daemon:toggle()
	if self.status then
		awful.spawn.easy_async_with_shell("nmcli radio wifi off", function()
			self:get_status()
		end)
	else
		awful.spawn.easy_async_with_shell("nmcli radio wifi on", function()
			self:get_status()
		end)
	end
end

function Wifi_daemon:scan()
	awesome.emit_signal("wifi:scan_started")
	local wifi_list = {}
	local nmcli = "nmcli -t -f 'SSID, BSSID, SECURITY, SIGNAL, ACTIVE' device wifi list"
	local delayed_call = gears.timer {
		timeout = 3,
		single_shot = true,
		callback = function()
			awful.spawn.easy_async_with_shell(nmcli, function(stdout, stderr, reason, code)
				for line in stdout:gmatch("[^\n]+") do
					local ssid, bssid_raw, security, signal, active = line:gsub([[\:]], [[\sep]]):match("(.*):(.*):(.*):(.*):(.*)")
					local bssid = string.gsub(bssid_raw, [[\sep]], ":")
					table.insert(wifi_list, { ssid = ssid, bssid = bssid, security = security, signal = signal, active = active })
				end
				if reason == "exit" then
					awesome.emit_signal("wifi:scan_finished", wifi_list)
				end
			end)
		end
	}
	delayed_call:start()
end

function Wifi_daemon:connect(ssid, bssid, security, passwd)
	local nmcli = "nmcli device wifi connect "
	if security:match("WPA") then
		awful.spawn.easy_async_with_shell(nmcli .. bssid .. " password " .. passwd, function(stdout, stderr)
			self:send_notification(stdout, stderr, ssid)
		end)
	else
		awful.spawn.easy_async_with_shell(nmcli .. bssid, function(stdout, stderr)
			self:send_notification(stdout, stderr, ssid)
		end)
	end
end

function Wifi_daemon:send_notification(stdout, stderr, ssid)
	if stdout:match("successfully") then
		naughty.notification {
			title = "Wifi",
			text = "connect successfully to\n" .. ssid
		}
	elseif stderr:match("Error") then
		naughty.notification {
			urgency = "critical",
			timeout = 5,
			title = "Wifi",
			text = "failed to connect\n" .. ssid
		}
	end
end

return Wifi_daemon
