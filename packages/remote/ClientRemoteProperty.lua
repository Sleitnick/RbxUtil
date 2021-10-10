-- ClientRemoteProperty
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteProperty = ClientRemoteProperty.new(valueObject: Instance)

	remoteProperty:Get(): any
	remoteProperty:Destroy(): void

	remoteProperty.Changed(newValue: any): Connection

--]]


local IS_SERVER = game:GetService("RunService"):IsServer()
local Signal = require(script.Parent.Parent.Signal)

--[=[
	@class ClientRemoteProperty
	@client
	Represents a RemoteProperty on the client.
]=]
local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty


--[=[
	@within ClientRemoteProperty
	@prop Changed Signal
	A signal which is fired anytime the value changes. The new value is passed to the connected functions.
]=]

--[=[
	@param instance Instance
	@return ClientRemoteProperty
	Constructs a ClientRemoteProperty that wraps around the instance created by
	the server-side RemoteProperty.
]=]
function ClientRemoteProperty.new(instance)

	assert(not IS_SERVER, "ClientRemoteProperty can only be created on the client")

	local self = setmetatable({
		_instance = instance;
		_value = nil;
		_isTable = instance:IsA("RemoteEvent");
	}, ClientRemoteProperty)

	local function SetValue(v)
		self._value = v
	end

	if self._isTable then
		self.Changed = Signal.new()
		self._change = instance.OnClientEvent:Connect(function(tbl)
			SetValue(tbl)
			self.Changed:Fire(tbl)
		end)
		SetValue(instance.TableRequest:InvokeServer())
	else
		SetValue(instance.Value)
		self.Changed = instance.Changed
		self._change = instance.Changed:Connect(SetValue)
	end

	return self

end


--[=[
	@return value: any
	Returns the value currently held.
]=]
function ClientRemoteProperty:Get()
	return self._value
end


--[=[
	Destroys the ClientRemoteProperty
]=]
function ClientRemoteProperty:Destroy()
	self._change:Disconnect()
	if self._isTable then
		self.Changed:Destroy()
	end
end


return ClientRemoteProperty
