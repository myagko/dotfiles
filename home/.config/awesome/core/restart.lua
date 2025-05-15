local capi = { awesome = awesome }

capi.awesome.connect_signal("request::restart", function()
	capi.awesome.restart()
end)
