-- Trove
-- Stephen Leitnick
-- October 16, 2021


local FN_MARKER = newproxy()

local RunService = game:GetService("RunService")


local function GetObjectCleanupFunction(object, cleanupMethod)
	local t = typeof(object)
	if t == "function" then
		return FN_MARKER
	end
	if cleanupMethod then
		return cleanupMethod
	end
	if t == "Instance" then
		return "Destroy"
	elseif t == "RBXScriptConnection" then
		return "Disconnect"
	elseif t == "table" then
		if typeof(t.Destroy) == "function" then
			return "Destroy"
		elseif typeof(t.Disconnect) == "function" then
			return "Disconnect"
		end
	end
	error("Failed to get cleanup function for object " .. t .. ": " .. tostring(object))
end


--[=[
	@class Trove
	A Trove is helpful for tracking any sort of object during
	runtime that needs to get cleaned up at some point.
]=]
local Trove = {}
Trove.__index = Trove


--[=[
	Constructs a Trove object.
]=]
function Trove.new()
	local self = setmetatable({}, Trove)
	self._objects = {}
	return self
end


--[=[
	@param class table
	@param ... any
	@return any
	Calls the `new` constructor function on the given table,
	adds the constructed object to the trove, and then
	returns the constructed object.
]=]
function Trove:Construct(class, ...)
	local object = class.new(...)
	return self:Add(object)
end


--[=[
	@param signal RBXScriptSignal
	@param fn (...: any) -> any
	@return RBXScriptConnection
	Connects the function to the signal, adds the connection
	to the trove, and then returns the connection.
]=]
function Trove:Connect(signal, fn)
	return self:Add(signal:Connect(fn))
end


--[=[
	@param name string
	@param priority number
	@param fn (dt: number) -> nil
	Calls `RunService:BindToRenderStep` and registers a function in the
	trove that will call `RunService:UnbindFromRenderStep` on cleanup.
]=]
function Trove:BindToRenderStep(name: string, priority: number, fn: (dt: number) -> nil)
	RunService:BindToRenderStep(name, priority, fn)
	self:Add(function()
		RunService:UnbindFromRenderStep(name)
	end)
end


--[=[
	@param object any -- Object to track
	@param cleanupMethod string? -- Optional cleanup name override
	@return object: any
	Adds an object to the trove. Once the trove is cleaned or
	destroyed, the object will also be cleaned up.
]=]
function Trove:Add(object: any, cleanupMethod: string?): any
	local cleanup = GetObjectCleanupFunction(object, cleanupMethod)
	table.insert(self._objects, {object, cleanup})
	return object
end


--[=[
	@param object any -- Object to remove
	Removes the object from the Trove and cleans it up.
]=]
function Trove:Remove(object: any): boolean
	local objects = self._objects
	for i,obj in ipairs(objects) do
		if obj[1] == object then
			local n = #objects
			objects[i] = objects[n]
			objects[n] = nil
			self:_cleanupObject(obj[1], obj[2])
			return true
		end
	end
	return false
end


--[=[
	Cleans up all objects in the trove.
]=]
function Trove:Clean()
	for _,obj in ipairs(self._objects) do
		self:_cleanupObject(obj[1], obj[2])
	end
	table.clear(self._objects)
end


function Trove:_cleanupObject(object, cleanupMethod)
	if cleanupMethod == FN_MARKER then
		object()
	else
		object[cleanupMethod](object)
	end
end


--[=[
	@param instance Instance
	@return RBXScriptConnection
	Attaches the trove to a Roblox instance. Once this
	instance is removed from the game (parent or ancestor's
	parent set to `nil`), the trove will automatically
	clean up.

	:::caution
	Will throw an error if `instance` is not a descendant
	of the game hierarchy.
	:::
]=]
function Trove:AttachToInstance(instance: Instance)
	assert(instance:IsDescendantOf(game), "Instance is not a descendant of the game hierarchy")
	return self:Connect(instance.AncestryChanged, function(child, parent)
		if not parent then
			self:Destroy()
		end
	end)
end


--[=[
	Destroys the Trove object. Forces `Clean` to run.
]=]
function Trove:Destroy()
	self:Clean()
end


return Trove
