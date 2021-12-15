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
	@client
	Because parts in StreamingEnabled games can stream in and out of existence at
	any point in time, it is hard to write code to interact with them. This is
	where Streamables come into play. Streamables will observe the existence of
	a given instance, and will signal when the instance exists and does not
	exist.

	The API is very simple. Create a Streamable that points to a certain parent
	and looks for a specific child instance (typically a BasePart). Then, call
	the `Observe` method to observe when the instance streams in and out.

	```lua
	local Streamable = require(packages.Streamable).Streamable

	-- Models might take a bit to load, but the model instance
	-- is never removed, thus we can use WaitForChild.
	local model = workspace:WaitForChild("MyModel")

	-- Watch for a specific part in the model:
	local partStreamable = Streamable.new(model, "SomePart")

	partStreamable:Observe(function(part, trove)
		print(part:GetFullName() .. " added")
		-- Run code on the part here.
		-- Use the trove to manage cleanup when the part goes away.
		trove:Add(function()
			-- General cleanup stuff
			print(part.Name .. " removed")
		end)
	end)

	-- Watch for the PrimaryPart of a model to exist:
	local primaryStreamable = Streamable.primary(model)
	primaryStreamable:Observe(function(primary, trove)
		print("Model now has a PrimaryPart:", primary.Name)
		trove:Add(function()
			print("Model's PrimaryPart has been removed")
		end)
	end)

	-- At any given point, accessing the Instance field will
	-- reference the observed part, if it exists:
	if partStreamable.Instance then
		print("Streamable has its instance:", partStreamable.Instance)
	end

	-- When/if done, call Destroy on the streamable, which will
	-- also clean up any observers:
	partStreamable:Destroy()
	primaryStreamable:Destroy()
	```

	For more information on the mechanics of how StreamingEnabled works
	and what sort of behavior to expect, see the
	[Content Streaming](https://developer.roblox.com/en-us/articles/content-streaming#technical-behavior)
	page. It is important to understand that only BaseParts and their descendants are streamed in/out,
	whereas other instances are loaded during the initial client load. It is also important to understand
	that streaming only occurs on the client. The server has immediate access to everything right away.
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
	Destroys the Streamable. Any observers will be disconnected,
	which also means that troves within observers will be cleaned
	up. This should be called when a streamable is no longer needed.
]=]
function Streamable:Destroy()
	self._trove:Destroy()
end


export type Streamable = typeof(Streamable.new(workspace, "X"))


return Streamable
