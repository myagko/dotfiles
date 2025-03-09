local lgi = require("lgi")
local dbus_proxy = require("external.dbus_proxy")
local gobject = require("gears.object")
local gtable = require("gears.table")
local gtimer = require("gears.timer")

local bluetooth = {}
local device = {}

local instance = nil

local function create_device_object(path)
	local device_object = gobject {}
	gtable.crush(device_object, device, true)
	device_object._private = {}

	device_object._private.device_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		interface = "org.bluez.Device1",
		path = path
	}

	device_object._private.battery_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		interface = "org.bluez.Battery1",
		path = path
	}

	device_object._private.properties_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		interface = "org.freedesktop.DBus.Properties",
		path = path
	}

	if device_object._private.device_proxy.Name ~= "" and device_object._private.device_proxy.Name ~= nil then
		device_object._private.properties_proxy:connect_signal("PropertiesChanged", function(_, _, props)
			if props.Connected ~= nil then
				device_object:emit_signal("property::connected", props.Connected)
			end
			if props.Paired ~= nil then
				device_object:emit_signal("property::paired", props.Paired)
			end
			if props.Trusted ~= nil then
				device_object:emit_signal("property::trusted", props.Trusted)
			end
			if props.Percentage ~= nil then
				device_object:emit_signal("property::percentage", props.Percentage)
			end
		end)

		return device_object
	end
end

function bluetooth:set_state(state)
	if self._private.adapter_proxy.Set then
		self._private.adapter_proxy:Set("org.bluez.Adapter1", "Powered", lgi.GLib.Variant("b", state))
		self._private.adapter_proxy.Powered = { signature = "b", value = state }
	end
end

function bluetooth:get_state()
	return self._private.adapter_proxy.Powered
end

function bluetooth:start_discovery()
	if self._private.adapter_proxy == nil then
		return
	end
	self._private.adapter_proxy:StartDiscovery()
end

function bluetooth:get_devices()
	return self.devices
end

function bluetooth:get_device(path)
	return self.devices[path]
end

function device:toggle_connect()
	if self._private.device_proxy.Connected == true then
		self._private.device_proxy:DisconnectAsync()
	else
		self._private.device_proxy:ConnectAsync()
	end
end

function device:toggle_trust()
	local trusted = self._private.device_proxy.Trusted
	if self._private.device_proxy.Set then
		self._private.device_proxy:Set("org.bluez.Device1", "Trusted", lgi.GLib.Variant("b", not trusted))
		self._private.device_proxy.Trusted = { signature = "b", value = not trusted }
	end
end

function device:toggle_pair()
	if self._private.device_proxy.Paired == true then
		self._private.device_proxy:PairAsync()
	else
		self._private.device_proxy:CancelPairingAsync()
	end
end

function device:get_connected()
	return self._private.device_proxy.Connected
end

function device:get_paired()
	return self._private.device_proxy.Paired
end

function device:get_trusted()
	return self._private.device_proxy.Trusted
end

function device:get_name()
	return self._private.device_proxy.Name
end

function device:get_icon()
	return self._private.device_proxy.Icon
end

function device:get_address()
	return self._private.device_proxy.Address
end

function device:get_percentage()
	return self._private.battery_proxy.Percentage
end

function device:get_path()
	return self._private.device_proxy.object_path
end

local function new()
	local ret = gobject {}
	gtable.crush(ret, bluetooth, true)
	ret._private = {}

	ret._private.object_manager_proxy = dbus_proxy.Proxy:new {
		bus = dbus_proxy.Bus.SYSTEM,
		name = "org.bluez",
		interface = "org.freedesktop.DBus.ObjectManager",
		path = "/"
	}

	if ret._private.object_manager_proxy then
		ret._private.adapter_proxy = dbus_proxy.Proxy:new {
			bus = dbus_proxy.Bus.SYSTEM,
			name = "org.bluez",
			interface = "org.bluez.Adapter1",
			path = "/org/bluez/hci0"
		}

		ret._private.properties_proxy = dbus_proxy.Proxy:new {
			bus = dbus_proxy.Bus.SYSTEM,
			name = "org.bluez",
			interface = "org.freedesktop.DBus.Properties",
			path = "/org/bluez/hci0"
		}

		ret.devices = {}

		if ret._private.object_manager_proxy.GetManagedObjects then
			local object_paths = ret._private.object_manager_proxy:GetManagedObjects()
			for path, _ in pairs(object_paths) do
				if path ~= nil and path:match("/org/bluez/hci0/dev") then
					ret.devices[path] = create_device_object(path)
				end
			end
		end

		ret._private.object_manager_proxy:connect_signal("InterfacesAdded", function(_, path)
			if path ~= nil and path:match("/org/bluez/hci0/dev") then
				ret.devices[path] = create_device_object(path)
				ret:emit_signal("device_added", path)
			end
		end)

		ret._private.object_manager_proxy:connect_signal("InterfacesRemoved", function(_, path)
			if path ~= nil then
				ret.devices[path] = nil
				ret:emit_signal("device_removed", path)
			end
		end)

		ret._private.properties_proxy:connect_signal("PropertiesChanged", function(_, _, props)
			if props.Powered ~= nil then
				ret:emit_signal("state", props.Powered)
			end
		end)
	end

	gtimer.delayed_call(function()
		ret:emit_signal("state", ret:get_state())
	end)

	return ret
end

if not instance then
	instance = new()
end

return instance
