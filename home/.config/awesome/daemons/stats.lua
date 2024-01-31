local awful = require("awful")

awful.widget.watch([[sh -c "vmstat 1 2 | tail -1 | awk '{print $15}'"]], 10, function(_, stdout)
	local usage = tostring(100 - tonumber(stdout))
	awesome.emit_signal("stats::cpu_usage", usage)
end)

awful.widget.watch([[sh -c "free -m | grep 'Mem' | awk '{print $2, $3}'"]], 10, function(_, stdout)
	local total = stdout:match("(%d+)%s+")
	local used = stdout:match("%s+(%d+)")
	local usage = tostring(math.floor(tonumber(used) / tonumber(total) * 100))
	awesome.emit_signal("stats::ram_usage", usage)
end)

awful.widget.watch([[sh -c "sensors"]], 10, function(_, stdout)
	--local clear_stdout = stdout:gsub("%s%(.-%)", "")
	awesome.emit_signal("stats::sensors", stdout)
end)
