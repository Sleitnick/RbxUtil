-- RemoteProperty
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteProperty = RemoteProperty.new(value: any [, overrideClass: string])

	remoteProperty:Get(): any
	remoteProperty:Set(value: any): void
	remoteProperty:Replicate(): void   [Only for table values]
	remoteProperty:Destroy(): void

	remoteProperty.Changed(newValue: any): Connection

--]]


local Signal = require(script.Parent.Parent.Signal)

local IS_SERVER = game:GetService("RunService"):IsServer()

local typeClassMap = {
	boolean = "BoolValue";
	string = "StringValue";
	table = "RemoteEvent";
	CFrame = "CFrameValue";
	Color3 = "Color3Value";
	BrickColor = "BrickColorValue";
	number = "NumberValue";
	Instance = "ObjectValue";
	Ray = "RayValue";
	Vector3 = "Vector3Value";
	["nil"] = "ObjectValue";
}

--[=[
	@class RemoteProperty
	@server
	Replicates a value to all clients.
	```lua
	local RemoteProperty = require(packages.Remote).RemoteProperty
	```
]=]
local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty


--[=[
	@param object any
	@return boolean
	Returns `true` if `object` is a RemoteProperty.
]=]
function RemoteProperty.Is(object)
	return type(object) == "table" and getmetatable(object) == RemoteProperty
end


--[=[
	@param value any
	@param overrideClass string?
	@return RemoteProperty
	Constructs a new RemoteProperty.
]=]
function RemoteProperty.new(value, overrideClass)

	assert(IS_SERVER, "RemoteProperty can only be created on the server")

	if overrideClass ~= nil then
		assert(type(overrideClass) == "string", "OverrideClass must be a string; got " .. type(overrideClass))
		assert(overrideClass:match("Value$"), "OverrideClass must be of super type ValueBase (e.g. IntValue); got " .. overrideClass)
	end

	local t = typeof(value)
	local class = overrideClass or typeClassMap[t]
	assert(class, "RemoteProperty does not support type \"" .. t .. "\"")

	local self = setmetatable({
		_value = value;
		_type = t;
		_isTable = (t == "table");
		_object = Instance.new(class);
	}, RemoteProperty)

	if self._isTable then
		local req = Instance.new("RemoteFunction")
		req.Name = "TableRequest"
		req.Parent = self._object
		function req.OnServerInvoke(_player)
			return self._value
		end
		self.Changed = Signal.new()
	else
		self.Changed = self._object.Changed
	end

	self:Set(value)

	return self

end


--[=[
	Forces the value to be replicated. This is only necessary when
	the value is a table, because the RemoteProperty does not
	know when changes to the table are made. Other value types
	are automatically replicated when changed.
]=]
function RemoteProperty:Replicate()
	if self._isTable then
		self:Set(self._value)
	end
end


--[=[
	@param value any
	Sets the value. This value is immediately replicated to all clients.
]=]
function RemoteProperty:Set(value)
	if self._isTable then
		self._object:FireAllClients(value)
		self.Changed:Fire(value)
	else
		self._object.Value = value
	end
	self._value = value
end


--[=[
	@return value: any
	Returns the current value held by the RemoteProperty.
]=]
function RemoteProperty:Get()
	return self._value
end


--[=[
	Destroys the RemoteProperty.
]=]
function RemoteProperty:Destroy()
	self._object:Destroy()
end


return RemoteProperty
