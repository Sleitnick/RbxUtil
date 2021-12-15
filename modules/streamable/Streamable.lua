--!strict

-- Streamable
-- Stephen Leitnick
-- March 03, 2021

type StreamableWithInstance = {
	Instance: Instance?,
	[any]: any,
}

local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)


--[=[
	@within Streamable
	@prop Instance Instance
	The current instance represented by the Streamable. If this
	is being observed, it will always exist. If not currently
	being observed, this will be `nil`.
]=]

--[=[
	@class Streamable
	Watches the existence of an instance within a specific parent.

	```lua
	local Streamable = require(packages.Streamable).Streamable
	```
]=]
local Streamable = {}
Streamable.__index = Streamable


--[=[
	@return Streamable
	@param parent Instance
	@param childName string

	Constructs a Streamable that watches for a direct child of name `childName`
	within the `parent` Instance. Call `Observe` to observe the existence of
	the child within the parent.
]=]
function Streamable.new(parent: Instance, childName: string)

	local self: StreamableWithInstance = {}
	setmetatable(self, Streamable)

	self._trove = Trove.new()
	self._shown = self._trove:Construct(Signal)
	self._shownTrove = Trove.new()
	self._trove:Add(self._shownTrove)

	self.Instance = parent:FindFirstChild(childName)

	local function OnInstanceSet()
		local instance = self.Instance
		if typeof(instance) == "Instance" then
			self._shown:Fire(instance, self._shownTrove)
			self._shownTrove:Connect(instance:GetPropertyChangedSignal("Parent"), function()
				if not instance.Parent then
					self._shownTrove:Clean()
				end
			end)
			self._shownTrove:Add(function()
				if self.Instance == instance then
					self.Instance = nil
				end
			end)
		end
	end

	local function OnChildAdded(child: Instance)
		if child.Name == childName and not self.Instance then
			self.Instance = child
			OnInstanceSet()
		end
	end

	self._trove:Connect(parent.ChildAdded, OnChildAdded)
	if self.Instance then
		OnInstanceSet()
	end

	return self

end


--[=[
	@return Streamable
	@param parent Model

	Constructs a streamable that watches for the PrimaryPart of the
	given `parent` Model.
]=]
function Streamable.primary(parent: Model)

	local self: StreamableWithInstance = {}
	setmetatable(self, Streamable)

	self._trove = Trove.new()
	self._shown = self._trove:Construct(Signal)
	self._shownTrove = Trove.new()
	self._trove:Add(self._shownTrove)

	self.Instance = parent.PrimaryPart

	local function OnPrimaryPartChanged()
		local primaryPart = parent.PrimaryPart
		self._shownTrove:Clean()
		self.Instance = primaryPart
		if primaryPart then
			self._shown:Fire(primaryPart, self._shownTrove)
		end
	end

	self._trove:Connect(parent:GetPropertyChangedSignal("PrimaryPart"), OnPrimaryPartChanged)
	if self.Instance then
		OnPrimaryPartChanged()
	end

	return self
	
end


--[=[
	@param handler (instance: Instance, trove: Trove) -> nil
	@return Connection

	Observes the instance. The handler is called anytime the
	instance comes into existence, and the trove given is
	cleaned up when the instance goes away.

	To stop observing, disconnect the returned connection.
]=]
function Streamable:Observe(handler)
	if self.Instance then
		task.spawn(handler, self.Instance, self._shownTrove)
	end
	return self._shown:Connect(handler)
end


--[=[
	Destroys the Streamable.
]=]
function Streamable:Destroy()
	self._trove:Destroy()
end


export type Streamable = typeof(Streamable.new(workspace, "X"))


return Streamable
