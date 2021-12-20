-- ClientRemoteProperty
-- Stephen Leitnick
-- December 20, 2021


local Promise = require(script.Parent.Parent.Parent.Promise)
local ClientRemoteSignal = require(script.Parent.ClientRemoteSignal)

--[=[
	@class ClientRemoteProperty
	@client
	Created via `ClientComm:GetProperty()`.
]=]
local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

function ClientRemoteProperty.new(re: RemoteEvent, inboundMiddleware: ClientMiddleware?, outboudMiddleware: ClientMiddleware?)
	local self = setmetatable({}, ClientRemoteProperty)
	self._rs = ClientRemoteSignal.new(re, inboundMiddleware, outboudMiddleware)
	self._ready = false
	self._value = nil
	self.Changed = self._rs
	self._changed = self._rs:Connect(function(value)
		self._value = value
	end)
	self._readyPromise = self:OnReady():andThen(function()
		self._readyPromise = nil
	end)
	self._rs:Fire()
	return self
end

--[=[
	@return any
	Gets the value of the property object.

	:::caution
	This value might not be ready right away. Use `OnReady()` or `IsReady()`
	before calling `Get()`.
	:::
]=]
function ClientRemoteProperty:Get()
	return self._value
end

--[=[
	@return Promise<any>
	Returns a Promise which resolves once the property object is
	ready to be used. The resolved promise will also contain the
	value of the property.

	```lua
	-- Use andThen clause:
	clientRemoteProperty:OnReady():andThen(function(initialValue)
		print(initialValue)
	end)

	-- Use await:
	local success, initialValue = clientRemoteProperty:OnReady():await()
	if success then
		print(initialValue)
	end
	```
]=]
function ClientRemoteProperty:OnReady()
	if self._ready then
		return Promise.resolve(self._value)
	end
	return Promise.fromEvent(self._rs, function(value)
		self._value = value
		self._ready = true
		return true
	end):andThen(function()
		return self._value
	end)
end

--[=[
	@return boolean
	Returns `true` if the property object is ready to be
	used. In other words, it has successfully gained
	connection to the server-side version and has synced
	in the initial value.

	```lua
	if clientRemoteProperty:IsReady() then
		local value = clientRemoteProperty:Get()
	end
	```
]=]
function ClientRemoteProperty:IsReady(): boolean
	return self._ready
end

--[=[
	@param observer (any) -> nil
	@return Connection
	Observes the value of the property. The observer will
	be called right when the value is first ready, and
	every time the value changes. This is safe to call
	immediately (i.e. no need to use `IsReady` or `OnReady`
	before using this method).

	```lua
	local function ObserveValue(value)
		print(value)
	end

	clientRemoteProperty:Observe(ObserveValue)
	```
]=]
function ClientRemoteProperty:Observe(observer: (any) -> nil)
	if self._ready then
		task.defer(observer, self._value)
	end
	return self.Changed:Connect(observer)
end

--[=[
	Destroys the ClientRemoteProperty object.
]=]
function ClientRemoteProperty:Destroy()
	self._rs:Destroy()
	if self._readyPromise then
		self._readyPromise:cancel()
	end
	self._changed:Disconnect()
end

return ClientRemoteProperty
