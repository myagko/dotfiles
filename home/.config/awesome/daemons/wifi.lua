local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local wifi_daemon = {}

function wifi_daemon:get_status()
    awful.spawn.easy_async_with_shell("nmcli g | sed 1d | awk '{print $3, $4}'", function(stdout)
        local hw, rd = stdout:match("(%w+)%s+(%w+)")
        if hw ~= "missing" and rd == "enabled" then
            self.status = true
            self:scan()
        else
            self.status = false
        end
        awesome.emit_signal("wifi:status", self.status)
    end)
end

function wifi_daemon:toggle()
    local delayed_nm_call = gears.timer {
        timeout = 3,
        single_shot = true,
        callback = function()
            self:get_status()
        end
    }

    if self.status then
        awful.spawn.easy_async_with_shell("nmcli radio wifi off", function()
            delayed_nm_call:start()
        end)
    else
        awful.spawn.easy_async_with_shell("nmcli radio wifi on", function()
            delayed_nm_call:start()
        end)
    end
end

function wifi_daemon:scan()
    awesome.emit_signal("wifi:scan_started")
    local wifi_list = {}
    local nmcli_command = "LANG=C nmcli -t -f 'SSID, BSSID, SECURITY, SIGNAL, ACTIVE' device wifi list"

    awful.spawn.easy_async_with_shell(nmcli_command, function(stdout, stderr, reason, code)
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

function wifi_daemon:connect(ssid, bssid, security, passwd)
    local nmcli_command = "LANG=C nmcli device wifi connect "
    if security:match("WPA") then
        awful.spawn.easy_async_with_shell(nmcli_command .. bssid .. " password " .. passwd, function(stdout, stderr)
            self:send_notification(stdout, stderr, ssid)
        end)
    else
        awful.spawn.easy_async_with_shell(nmcli_command .. bssid, function(stdout, stderr)
            self:send_notification(stdout, stderr, ssid)
        end)
    end
end

function wifi_daemon:send_notification(stdout, stderr, ssid)
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

return wifi_daemon
