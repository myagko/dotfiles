-- author: https://github.com/Kasper24
local lgi = require("lgi")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local gdebug = require("gears.debug")
local helpers = require("helpers")
local dbus_proxy = require("modules.dbus_proxy")

local _NM_status, NM = pcall(function()
	return require("lgi").NM
end)
if not _NM_status or not NM then
	gdebug.print_warning(
		"Can't load NetworkManager introspection. "
			.. "Seems like NetworkManager is not installed or `lua-lgi` was built with an incompatible NetworkManager version. "
			.. "Network related UI will not work!"
	)
	return gobject {}
end

local network = {}
local access_point = {}
local instance = nil

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

local function create_profile(access_point, password, auto_connect)
	local s_con = {
		--["interface-name"] = lgi.GLib.Variant("s", access_point.device_interface),
		["uuid"] = lgi.GLib.Variant("s", generate_uuid()),
		["id"] = lgi.GLib.Variant("s", access_point.ssid),
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
	if access_point.security ~= "" then
		if access_point.security:match("WPA") ~= nil then
			s_wsec["key-mgmt"] = lgi.GLib.Variant("s", "wpa-psk")
			s_wsec["auth-alg"] = lgi.GLib.Variant("s", "open")
			s_wsec["psk"] = lgi.GLib.Variant("s", helpers.string_trim(password))
		else
			s_wsec["key-mgmt"] = lgi.GLib.Variant("s", "None")
			s_wsec["wep-key-type"] = lgi.GLib.Variant("s", NM.WepKeyType.PASSPHRASE)
			s_wsec["wep-key0"] = lgi.GLib.Variant("s", helpers.string_trim(password))
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

local function on_wifi_device_state_changed(self, proxy, new_state, old_state, reason)
	local active_access_point_proxy = dbus_proxy.Proxy:new({
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager.AccessPoint",
		path = self._private.wifi_proxy.ActiveAccessPoint,
	})

	self:emit_signal(tostring(active_access_point_proxy.HwAddress) .. "::state", new_state, old_state)
	if new_state == network.DeviceState.ACTIVATED then
		local ssid = NM.utils_ssid_to_utf8(active_access_point_proxy.Ssid)
		self:emit_signal("access_point::connected", ssid, active_access_point_proxy.Strength)
	end
end

local function get_access_point_connections(self, ssid)
	local connection_proxies = {}

	local connections = self._private.settings_proxy:ListConnections()
	for _, connection_path in ipairs(connections) do
		local connection_proxy = dbus_proxy.Proxy:new({
			bus = dbus_proxy.Bus.SYSTEM,
			name = "org.freedesktop.NetworkManager",
			interface = "org.freedesktop.NetworkManager.Settings.Connection",
			path = connection_path,
		})

		if string.find(connection_proxy.Filename, ssid) then
			table.insert(connection_proxies, connection_proxy)
		end
	end

	return connection_proxies
end

local function get_wifi_proxy(self)
	local devices = self._private.client_proxy:GetDevices()
	for _, device_path in ipairs(devices) do
		local device_proxy = dbus_proxy.Proxy:new({
			bus = dbus_proxy.Bus.SYSTEM,
			name = "org.freedesktop.NetworkManager",
			interface = "org.freedesktop.NetworkManager.Device",
			path = device_path,
		})

		if device_proxy.DeviceType == network.DeviceType.WIFI then
			self._private.device_proxy = device_proxy
			self._private.wifi_proxy = dbus_proxy.Proxy:new({
				bus = dbus_proxy.Bus.SYSTEM,
				name = "org.freedesktop.NetworkManager",
				interface = "org.freedesktop.NetworkManager.Device.Wireless",
				path = device_path,
			})

			self._private.device_proxy:connect_signal("StateChanged", function(proxy, new_state, old_state, reason)
				on_wifi_device_state_changed(self, proxy, new_state, old_state, reason)
			end)
		end
	end
end

function network:scan_access_points()
	if self._private.wifi_proxy == nil then
		return
	end

	self._private.access_points = {}

	self._private.wifi_proxy:RequestScanAsync(function(proxy, context, success, failure)
		if failure ~= nil then
			self:emit_signal("scan_access_points::failed", tostring(failure), tostring(failure.code))
			return
		end

		local access_points = self._private.wifi_proxy:GetAccessPoints()
		for _, access_point_path in ipairs(access_points) do
			local access_point_proxy = dbus_proxy.Proxy:new({
				bus = dbus_proxy.Bus.SYSTEM,
				name = "org.freedesktop.NetworkManager",
				interface = "org.freedesktop.NetworkManager.AccessPoint",
				path = access_point_path,
			})

			if access_point_proxy.Ssid ~= nil then
				local ssid = NM.utils_ssid_to_utf8(access_point_proxy.Ssid)
				local security = flags_to_security(
					access_point_proxy.Flags,
					access_point_proxy.WpaFlags,
					access_point_proxy.RsnFlags
				)
				local password = ""
				local connections = get_access_point_connections(self, ssid)

				for _, connection in ipairs(connections) do
					if string.find(connection.Filename, ssid) then
						local secrets = connection:GetSecrets("802-11-wireless-security")
						if secrets ~= nil then
							password = secrets["802-11-wireless-security"].psk
						end
					end
				end

				local ret = {
					raw_ssid = access_point_proxy.Ssid,
					ssid = ssid,
					security = security,
					password = password,
					strength = access_point_proxy.Strength,
					path = access_point_path,
					hw_address = access_point_proxy.HwAddress,
					device_interface = self._private.device_proxy.Interface,
					device_proxy_path = self._private.device_proxy.object_path,
					network_manager = self,
				}
				gtable.crush(ret, access_point, true)

				table.insert(self._private.access_points, ret)
			end
		end

		table.sort(self._private.access_points, function(a, b)
			return a.strength > b.strength
		end)

		self:emit_signal("scan_access_points::success", self._private.access_points)
	end, {
		call_id = "my-id",
	}, {})
end

function network:disconnect_from_active_access_point()
	self._private.client_proxy:DeactivateConnection(self._private.device_proxy.ActiveConnection)
end

function network:toggle_wireless_state()
	local enable = not self._private.client_proxy.WirelessEnabled
	if enable == true then
		self:set_network_state(true)
	end

	self._private.client_proxy:Set("org.freedesktop.NetworkManager", "WirelessEnabled", lgi.GLib.Variant("b", enable))
	self._private.client_proxy.WirelessEnabled = {
		signature = "b",
		value = enable,
	}
end

function network:set_network_state(state)
	self._private.client_proxy:Enable(state)
end

function network:get_wireless_state()
	return self._private.client_proxy.WirelessEnabled
end

function network:get_access_points()
	return self._private.access_points
end

function access_point:connect(password, auto_connect)
	local connections = get_access_point_connections(self.network_manager, self.ssid)
	local profile = create_profile(self, password, auto_connect)

	if #connections == 0 then
		self.network_manager._private.client_proxy:AddAndActivateConnectionAsync(
			function(proxy, context, success, failure)
				if failure ~= nil then
					self.network_manager:emit_signal(
						"activate_access_point::failed",
						tostring(failure),
						tostring(failure.code)
					)
					return
				end

				self.network_manager:emit_signal("activate_access_point::success", self.ssid)
			end,
			{ call_id = "my-id" },
			profile,
			self.device_proxy_path,
			self.path
		)
	else
		connections[1]:Update(profile)
		self.network_manager._private.client_proxy:ActivateConnectionAsync(function(proxy, context, success, failure)
			if failure ~= nil then
				self.network_manager:emit_signal(
					"activate_access_point::failed",
					tostring(failure),
					tostring(failure.code)
				)
				return
			end

			self.network_manager:emit_signal("activate_access_point::success", self.ssid)
		end, { call_id = "my-id" }, connections[1].object_path, self.device_proxy_path, self.path)
	end
end

function access_point:is_active()
	return self.path == self.network_manager._private.wifi_proxy.ActiveAccessPoint
end

function access_point:toggle(password, auto_connect)
	if self:is_active() then
		self.network_manager:disconnect_from_active_access_point()
	else
		self:connect(password, auto_connect)
	end
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, network, true)

	ret._private = {}
	ret._private.access_points = {}

	ret._private.client_proxy = dbus_proxy.Proxy:new({
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager",
		path = "/org/freedesktop/NetworkManager",
	})

	ret._private.settings_proxy = dbus_proxy.Proxy:new({
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.NetworkManager.Settings",
		path = "/org/freedesktop/NetworkManager/Settings",
	})

	local client_properties_proxy = dbus_proxy.Proxy:new({
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.freedesktop.NetworkManager",
		interface = "org.freedesktop.DBus.Properties",
		path = "/org/freedesktop/NetworkManager",
	})

	client_properties_proxy:connect_signal("PropertiesChanged", function(_, interface, data)
		if data.WirelessEnabled ~= nil and ret._private.WirelessEnabled ~= data.WirelessEnabled then
			ret._private.WirelessEnabled = data.WirelessEnabled
			ret:emit_signal("wireless_state", data.WirelessEnabled)

			if data.WirelessEnabled == true then
				gtimer.start_new(5, function()
					ret:scan_access_points()
					return false
				end)
			end
		end
	end)

	get_wifi_proxy(ret)
	ret:scan_access_points()

	gtimer.delayed_call(function()
		ret:emit_signal("wireless_state", ret._private.client_proxy.WirelessEnabled)

		if ret._private.wifi_proxy then
			local active_access_point = ret._private.wifi_proxy.ActiveAccessPoint
			if ret._private.device_proxy.State == network.DeviceState.ACTIVATED and active_access_point ~= "/" then
				local active_access_point_proxy = dbus_proxy.Proxy:new({
					bus = dbus_proxy.Bus.SYSTEM,
					name = "org.freedesktop.NetworkManager",
					interface = "org.freedesktop.NetworkManager.AccessPoint",
					path = active_access_point,
				})

				local ssid = NM.utils_ssid_to_utf8(active_access_point_proxy.Ssid)
				ret:emit_signal("access_point::connected", ssid, active_access_point_proxy.Strength)
			end
		end
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
