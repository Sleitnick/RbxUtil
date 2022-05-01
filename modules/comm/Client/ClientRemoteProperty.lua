-- ClientRemoteProperty
-- Stephen Leitnick
-- December 20, 2021


local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local ClientRemoteSignal = require(script.Parent.ClientRemoteSignal)
local Types = require(script.Parent.Parent.Types)

--[=[
	@within ClientRemoteProperty
	@prop Changed Signal<any>

	Fires when the property receives an updated value
	from the server.

	```lua
	clientRemoteProperty.Changed:Connect(function(value)
		print("New value", value)
	end)
	```
]=]

--[=[
	@class ClientRemoteProperty
	@client
	Created via `ClientComm:GetProperty()`.
]=]
local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

function ClientRemoteProperty.new(re: RemoteEvent, inboundMiddleware: Types.ClientMiddleware?, outboudMiddleware: Types.ClientMiddleware?)
	local self = setmetatable({}, ClientRemoteProperty)
	self._rs = ClientRemoteSignal.new(re, inboundMiddleware, outboudMiddleware)
	self._ready = false
	self._value = nil
	self.Changed = Signal.new()
	self._readyPromise = self:OnReady():andThen(function()
		self._readyPromise = nil
		self.Changed:Fire(self._value)
		self._changed = self._rs:Connect(function(value)
			if value == self._value then return end
			self._value = value
			self.Changed:Fire(value)
		end)
	end)
	self._rs:Fire()
	return self
end

--[=[
	Gets the value of the property object.

	:::caution
	This value might not be ready right away. Use `OnReady()` or `IsReady()`
	before calling `Get()`. If not ready, this value will return `nil`.
	:::
]=]
function ClientRemoteProperty:Get(): any
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

	Observing is essentially listening to `Changed`, but
	also sends the initial value right away (or at least
	once `OnReady` is completed).

	```lua
	local function ObserveValue(value)
		print(value)
	end

	clientRemoteProperty:Observe(ObserveValue)
	```
]=]
function ClientRemoteProperty:Observe(observer: (any) -> ())
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
	if self._changed then
		self._changed:Disconnect()
	end
	self.Changed:Destroy()
end

return ClientRemoteProperty
