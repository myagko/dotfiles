local lgi = require("lgi")
local dbus_proxy = require("external.dbus_proxy")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local string_trim = require("helpers").string_trim

local _NM_status, NM = pcall(function()
	return require("lgi").NM
end)

if not _NM_status or not NM then
	return gobject {}
end

local network = {}
local wired = {}
local wireless = {}
local connection = {}
local access_point = {}

network.NMState = {
	UNKNOWN = 0,
	ASLEEP = 10,
	DISCONNECTED = 20,
	DISCONNECTING = 30,
	CONNECTING = 40,
	CONNECTED_LOCAL = 50,
	CONNECTED_SITE = 60,
	CONNECTED_GLOBAL = 70,
}

network.DeviceType = {
	ETHERNET = 1,
	WIFI = 2,
}

network.DeviceState = {
	UNKNOWN = 0,
	UNMANAGED = 10,
	UNAVAILABLE = 20,
	DISCONNECTED = 30,
	PREPARE = 40,
	CONFIG = 50,
	NEED_AUTH = 60,
	IP_CONFIG = 70,
	IP_CHECK = 80,
	SECONDARIES = 90,
	ACTIVATED = 100,
	DEACTIVATING = 110,
	FAILED = 120,
}

function network.device_state_to_string(state)
	local device_state_to_string = {
		[0] = "Unknown",
		[10] = "Unmanaged",
		[20] = "Unavailable",
		[30] = "Disconnected",
		[40] = "Prepare",
		[50] = "Config",
		[60] = "Need Auth",
		[70] = "IP Config",
		[80] = "IP Check",
		[90] = "Secondaries",
		[100] = "Activated",
		[110] = "Deactivated",
		[120] = "Failed",
	}

	return device_state_to_string[state]
end

local function flags_to_security(flags, wpa_flags, rsn_flags)
	local str = ""
	if flags == 1 and wpa_flags == 0 and rsn_flags == 0 then
		str = str .. " WEP"
	end
	if wpa_flags ~= 0 then
		str = str .. " WPA1"
	end
	if not rsn_flags ~= 0 then
		str = str .. " WPA2"
	end
	if wpa_flags == 512 or rsn_flags == 512 then
		str = str .. " 802.1X"
	end

	return (str:gsub("^%s", ""))
end

local function generate_uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	local uuid = string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
	end)
	return uuid
end

local function create_ap_profile(ap, password, auto_connect)
	local s_con = {
		["uuid"] = lgi.GLib.Variant("s", generate_uuid()),
		["id"] = lgi.GLib.Variant("s", ap:get_ssid()),
		["type"] = lgi.GLib.Variant("s", "802-11-wireless"),
		["autoconnect"] = lgi.GLib.Variant("b", auto_connect),
	}

	local s_ip4 = {
		["method"] = lgi.GLib.Variant("s", "auto"),
	}

	local s_ip6 = {
		["method"] = lgi.GLib.Variant("s", "auto"),
	}

	local s_wifi = {
		["mode"] = lgi.GLib.Variant("s", "infrastructure"),
	}

	local s_wsec = {}
	if ap:get_security() ~= "" then
		if ap:get_security():match("WPA") ~= nil then
			s_wsec["key-mgmt"] = lgi.GLib.Variant("s", "wpa-psk")
			s_wsec["auth-alg"] = lgi.GLib.Variant("s", "open")
			s_wsec["psk"] = lgi.GLib.Variant("s", string_trim(password))
		else
			s_wsec["key-mgmt"] = lgi.GLib.Variant("s", "None")
			s_wsec["wep-key-type"] = lgi.GLib.Variant("s", NM.WepKeyType.PASSPHRASE)
			s_wsec["wep-key0"] = lgi.GLib.Variant("s", string_trim(password))
		end
	end

	return {
		["connection"] = s_con,
		["ipv4"] = s_ip4,
		["ipv6"] = s_ip6,
		["802-11-wireless"] = s_wifi,
		["802-11-wireless-security"] = s_wsec,
	}
end

local function create_connection_object(path)
	if not path or path == "/" then return end

	local connection_object = gobject {}
	gtable.crush(connection_object, connection, true)
	connection_object._private = {}
	connection_object._private.connection_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager.Settings.Connection",
		path = path
	}

	return connection_object
end

local function create_access_point_object(path)
	if not path or path == "/" then return end

	local access_point_object = gobject {}
	gtable.crush(access_point_object, access_point, true)
	access_point_object._private = {}
	access_point_object._private.access_point_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager.AccessPoint",
		path = path
	}

	return access_point_object:get_ssid() ~= nil and access_point_object
end

function network:get_network_state()
	return self._private.client_proxy.NetworkingEnabled
end

function network:set_network_state(state)
	if self._private.client_proxy.Enable then
		self._private.client_proxy:Enable(state)
	end
end

function network:get_wireless_state()
	return self._private.client_proxy.WirelessEnabled
end

function network:set_wireless_state(state)
	if state == true then
		self:set_network_state(true)
	end

	if self._private.client_proxy.Set then
		self._private.client_proxy:Set("org.freedesktop.NetworkManager", "WirelessEnabled", lgi.GLib.Variant("b", state))
		self._private.client_proxy.WirelessEnabled = { signature = "b", value = state }
	end
end

function network:get_connections()
	return self.connections
end

function network:get_connection(path)
	return self.connections[path]
end

function network:connect_access_point(ap, password, auto_connect)
	if not ap then return end
	password = password or ""
	auto_connect = auto_connect or true

	local profile = create_ap_profile(ap, password, auto_connect)

	local ap_connections = {}
	for _, con in pairs(self.connections) do
		if string.find(con:get_filename(), ap:get_ssid()) then
			table.insert(ap_connections, con)
		end
	end

	if #ap_connections == 0 then
		self._private.client_proxy:AddAndActivateConnectionAsync(
			function(_, context, success, failure)
				if failure ~= nil then
					self:emit_signal("activate_access_point_failed", tostring(failure), tostring(failure.code))
					return
				end
				self:emit_signal("activate_access_point_success", ap)
			end,
			{ call_id = "my-id" },
			profile,
			self.wireless._private.device_proxy.object_path,
			ap._private.access_point_proxy.object_path
		)
	else
		ap_connections[1]._private.connection_proxy:Update(profile)
		self._private.client_proxy:ActivateConnectionAsync(
			function(_, context, success, failure)
				if failure ~= nil then
					self:emit_signal("activate_access_point_failed", tostring(failure), tostring(failure.code))
					return
				end
				self:emit_signal("activate_access_point_success", ap)
			end,
			{ call_id = "my-id" },
			ap_connections[1]._private.connection_proxy.object_path,
			self.wireless._private.device_proxy.object_path,
			ap._private.access_point_proxy.object_path
		)
	end
end

function network:disconnect_active_access_point()
	self._private.client_proxy:DeactivateConnection(
		self.wireless._private.device_proxy.ActiveConnection
	)
end

function wired:get_hw_address()
	return self._private.device_proxy.HwAddress
end

function wireless:get_hw_address()
	return self._private.device_proxy.HwAddress
end

function wireless:get_access_points()
	return self.access_points
end

function wireless:get_access_point(path)
	return self.access_points[path]
end

function wireless:scan_access_points()
	if self._private.device_proxy == nil then return end
	self._private.device_proxy:RequestScanAsync(
		function(_, context, success, failure)
			if failure ~= nil then
				self:emit_signal("scan_access_points_failed", tostring(failure), tostring(failure.code))
				return
			end
			self:emit_signal("scan_access_points_success", self.access_points)
		end,
		{ call_id = "my-id" },
		{}
	)
end

function wireless:get_active_access_point()
	return self:get_access_point(self._private.wireless_proxy.ActiveAccessPoint)
end

function connection:get_filename()
	return self._private.connection_proxy.Filename
end

function connection:get_path()
	return self._private.connection_proxy.object_path
end

function access_point:get_ssid()
	return NM.utils_ssid_to_utf8(self._private.access_point_proxy.Ssid)
end

function access_point:get_hw_address()
	return self._private.access_point_proxy.HwAddress
end

function access_point:get_security()
	return flags_to_security(
		self._private.access_point_proxy.Flags,
		self._private.access_point_proxy.WpaFlags,
		self._private.access_point_proxy.RsnFlags
	)
end

function access_point:get_strength()
	return self._private.access_point_proxy.Strength
end

function access_point:get_path()
	return self._private.access_point_proxy.object_path
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, network, true)
	ret._private = {}

	ret._private.client_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager",
		path = "/org/freedesktop/NetworkManager"
	}

	ret._private.settings_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager.Settings",
		path = "/org/freedesktop/NetworkManager/Settings"
	}

	ret._private.properties_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.DBus.Properties",
		path = "/org/freedesktop/NetworkManager"
	}

	ret._private.properties_proxy:connect_signal("PropertiesChanged", function(_, _, props)
		if props.NetworkingEnabled ~= nil then
			ret:emit_signal("network_state", props.NetworkingEnabled)
		end
		if props.WirelessEnabled ~= nil then
			ret:emit_signal("wireless_state", props.WirelessEnabled)
		end
	end)

	ret.connections = {}

	local connection_paths = ret._private.settings_proxy:ListConnections()
	for _, connection_path in ipairs(connection_paths) do
		local connection_object = create_connection_object(connection_path)
		ret.connections[connection_path] = connection_object
	end

	ret._private.settings_proxy:connect_signal("NewConnection", function(_, path)
		local connection_object = create_connection_object(path)
		ret.connections[path] = connection_object
		ret:emit_signal("connection_added", path)
	end)

	ret._private.settings_proxy:connect_signal("ConnectionRemoved", function(_, path)
		ret.connections[path] = nil
		ret:emit_signal("connection_removed", path)
	end)

	ret.wired = gobject {}
	gtable.crush(ret.wired, wired, true)
	ret.wired._private = {}

	ret.wireless = gobject {}
	gtable.crush(ret.wireless, wireless, true)
	ret.wireless._private = {}

	local device_paths = ret._private.client_proxy:GetDevices()
	for _, device_path in ipairs(device_paths) do
		local device_proxy = dbus_proxy.Proxy:new {
			bus = dbus_proxy.Bus.SYSTEM,
			name = "org.freedesktop.NetworkManager",
			interface = "org.freedesktop.NetworkManager.Device",
			path = device_path
		}

		if device_proxy.DeviceType == network.DeviceType.ETHERNET then
			ret.wired._private.device_proxy = device_proxy
			ret.wired._private.wired_proxy = dbus_proxy.Proxy:new {
				bus = dbus_proxy.Bus.SYSTEM,
				name = "org.freedesktop.NetworkManager",
				interface = "org.freedesktop.NetworkManager.Device.Wired",
				path = device_path,
			}
		elseif device_proxy.DeviceType == network.DeviceType.WIFI then
			ret.wireless._private.device_proxy = device_proxy
			ret.wireless._private.wireless_proxy = dbus_proxy.Proxy:new {
				bus = dbus_proxy.Bus.SYSTEM,
				name = "org.freedesktop.NetworkManager",
				interface = "org.freedesktop.NetworkManager.Device.Wireless",
				path = device_path,
			}
			ret.wireless.access_points = {}
		end
	end

	if ret.wireless._private.device_proxy then
		local access_point_paths = ret.wireless._private.device_proxy:GetAccessPoints()
		for _, access_point_path in ipairs(access_point_paths) do
			local access_point_object = create_access_point_object(access_point_path)
			if access_point_object then
				ret.wireless.access_points[access_point_path] = access_point_object
			end
		end
	end

	if ret.wireless._private.wireless_proxy then
		ret.wireless._private.wireless_proxy:connect_signal("AccessPointAdded", function(_, path)
			local access_point_object = create_access_point_object(path)
			if access_point_object then
				ret.wireless.access_points[path] = access_point_object
				ret.wireless:emit_signal("access_point_added", path)
			end
		end)

		ret.wireless._private.wireless_proxy:connect_signal("AccessPointRemoved", function(_, path)
			ret.wireless.access_points[path] = nil
			ret.wireless:emit_signal("access_point_removed", path)
		end)
	end

	gtimer.delayed_call(function()
		ret:emit_signal("network_state", ret:get_network_state())
		ret:emit_signal("wireless_state", ret:get_wireless_state())
	end)

	return ret
end

local instance = nil
local function get_default()
	if not instance then
		instance = new()
	end
	return instance
end

return {
	get_default = get_default
}
