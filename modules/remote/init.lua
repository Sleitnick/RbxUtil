-- Remote
-- Stephen Leitnick
-- November 08, 2021


--[=[
	@class Remote

	The Remote module provides access to various remote communication classes.

	- [RemoteSignal](/api/RemoteSignal)
	- [RemoteProperty](/api/RemoteProperty)
	- [ClientRemoteSignal](/api/ClientRemoteSignal)
	- [ClientRemoteProperty](/api/ClientRemoteProperty)

	```lua
	local Remote = require(packages.Remote)
	
	local RemoteSignal = Remote.RemoteSignal
	local RemoteProperty = Remote.RemoteProperty
	local ClientRemoteSignal = Remote.ClientRemoteSignal
	local ClientRemoteProperty = Remote.ClientRemoteProperty
	```
]=]
local Remote = {
	RemoteSignal = require(script.RemoteSignal);
	RemoteProperty = require(script.RemoteProperty);
	ClientRemoteSignal = require(script.ClientRemoteSignal);
	ClientRemoteProperty = require(script.ClientRemoteProperty);
}

return Remote
