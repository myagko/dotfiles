pcall(require, "luarocks.loader")
collectgarbage("incremental", 110, 1000)
require("core")
require("ui")

local capi = { awesome = awesome }
capi.awesome.connect_signal("request::restart", function()
	capi.awesome.restart()
end)
