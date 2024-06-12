local awful = require("awful")

local bluetooh = {}

function bluetooh:get_status()
    awful.spawn.easy_async_with_shell("LAMG=C timeout 1 bluetoothctl show", function(stdout)
        self.status = stdout:match("Powered:%s+(%w+)") == "yes"
        awesome.emit_signal("bluetooth:status", self.status)
    end)
end

function bluetooh:toggle()
    if not self.status then
        awful.spawn.easy_async_with_shell("bluetoothctl power on", function()
            self:get_status()
        end)
    else
        awful.spawn.easy_async_with_shell("bluetootctl power off", function()
            self:get_status()
        end)
    end
end

return bluetooh
