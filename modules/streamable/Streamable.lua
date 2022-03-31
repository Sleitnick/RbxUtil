--!strict

-- Streamable
-- Stephen Leitnick
-- March 03, 2021

type StreamableWithInstance = {
	Instance: Instance?,
	[any]: any,
}

type StreamableObserveHandler = () -> ()
type CleanupFn = () -> ()

local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)


--[=[
	@within Streamable
	@type CleanupFn () -> ()
	A simple function that is used to clean up a task.
]=]

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

	partStreamable:Observe(function(part)
		print(part:GetFullName() .. " added")
		-- Run code on the part here.

		-- The returned function is called when the part goes out of existence:
		return function()
			-- General cleanup stuff
			print(part.Name .. " removed")
		end
	end)

	-- Watch for the PrimaryPart of a model to exist:
	local primaryStreamable = Streamable.primary(model)
	primaryStreamable:Observe(function(primary)
		print("Model now has a PrimaryPart:", primary.Name)
		return function()
			print("Model's PrimaryPart has been removed")
		end
	end)

	-- Stop an observer by running the function the observer returns:
	local cleanupObserver = primaryStreamable:Observe(function(primary) ... end)
	cleanupObserver()

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

	Constructs a Streamable that watches for a direct child of name `childName`
	within the `parent` Instance. Call `Observe` to observe the existence of
	the child within the parent.

	```lua
	local streamable = Streamable.new(someInstance, "SomeChild")
	```
]=]
function Streamable.new(parent: Instance, childName: string)

	local self: StreamableWithInstance = {}
	setmetatable(self, Streamable)

	self._trove = Trove.new()
	self._shown = self._trove:Construct(Signal)
	self._shownTrove = self._trove:Extend()

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

	Constructs a streamable that watches for the PrimaryPart of the
	given `parent` Model.

	```lua
	local streamable = Streamable.primary(someModel)
	```
]=]
function Streamable.primary(parent: Model)

	local self: StreamableWithInstance = {}
	setmetatable(self, Streamable)

	self._trove = Trove.new()
	self._shown = self._trove:Construct(Signal)
	self._shownTrove = self._trove:Extend()

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
	Observes the instance. The handler is called anytime the
	instance comes into existence. The handler can return a
	function that will be called once the instance goes out
	of existence _or_ when this observer is cleaned up.

	To stop observing, call the returned function.

	Destroying the streamable will also stop the observer, as
	well as any other observers.

	```lua
	local observerCleanup = streamable:Observe(function(instance: Instance)
		-- Runs when the instance comes into existence
		print(instance.Name .. " exists")

		return function()
			print(instance.Name .. " not longer exists")
			-- Runs when the instance goes out of existence
			-- Any cleanup necessary
		end
	end)

	-- If the observer is no longer needed, it can be cleaned up by calling
	-- the returned function:
	observerCleanup()
	```
]=]
function Streamable:Observe(handler: (instance: Instance) -> CleanupFn?): CleanupFn
	local cleanupFn
	local function OnShown(instance: Instance)
		local cleanup = handler(instance)
		if type(cleanup) == "function" then
			cleanupFn = function()
				cleanupFn = nil
				cleanup()
			end
			self._shownTrove:Add(cleanupFn)
		end
	end
	if self.Instance then
		task.spawn(OnShown, self.Instance)
	end
	local connection = self._shown:Connect(OnShown)
	local function CleanupObserver()
		connection:Disconnect()
		if cleanupFn then
			local cleanup = cleanupFn
			cleanupFn = nil
			self._shownTrove:Remove(cleanup)
		end
	end
	self._trove:Add(CleanupObserver)
	return function()
		self._trove:Remove(CleanupObserver)
	end
end

--[=[
	Destroys the streamable. All observers will be cleaned up.
]=]
function Streamable:Destroy()
	self._trove:Destroy()
end

export type Streamable = typeof(Streamable.new(workspace, "X"))

return Streamable
