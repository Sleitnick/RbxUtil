-- Component
-- Stephen Leitnick
-- November 26, 2021


type AncestorList = {Instance}

--[=[
	@type ExtensionFn (component) -> nil
	@within Component
]=]
type ExtensionFn = (any) -> nil


--[=[
	@interface Extension
	@within Component
	.Constructing ExtensionFn?
	.Constructed ExtensionFn?
	.Starting ExtensionFn?
	.Started ExtensionFn?
	.Stopping ExtensionFn?
	.Stopped ExtensionFn?

	An extension allows the ability to extend the behavior of
	components. This is useful for adding injection systems or
	extending the behavior of components.

	For instance, an extension could be created to simply log
	when the various lifecycle stages run on the component:

	```lua
	local Logger = {}
	function Logger.Constructing(component) print("Constructing", component) end
	function Logger.Constructed(component) print("Constructed", component) end
	function Logger.Starting(component) print("Starting", component) end
	function Logger.Started(component) print("Started", component) end
	function Logger.Stopping(component) print("Stopping", component) end
	function Logger.Stopped(component) print("Stopped", component) end

	local MyComponent = Component.new({Tag = "MyComponent", Extensions = {Logger}})
	```
]=]
type Extension = {
	Constructing: ExtensionFn?,
	Constructed: ExtensionFn?,
	Starting: ExtensionFn?,
	Started: ExtensionFn?,
	Stopping: ExtensionFn?,
	Stopped: ExtensionFn?,
}

--[=[
	@interface ComponentConfig
	@within Component
	.Tag string -- CollectionService tag to use
	.Ancestors {Instance}? -- Optional array of ancestors in which components will be started
	.Extensions {Extension}? -- Optional array of extension objects

	Component configuration passed to `Component.new`.

	- If no Ancestors option is included, it defaults to `{workspace, game.Players}`.
	- If no Extensions option is included, it defaults to a blank table `{}`.
]=]
type ComponentConfig = {
	Tag: string,
	Ancestors: AncestorList?,
	Extensions: {Extension}?,
}

--[=[
	@prop Started Signal
	@within Component

	Fired when a new instance of a component is started.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})

	MyComponent.Started:Connect(function(component) end)
	```
]=]

--[=[
	@prop Stopped Signal
	@within Component

	Fired when an instance of a component is stopped.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})

	MyComponent.Stopped:Connect(function(component) end)
	```
]=]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)

local IS_SERVER = RunService:IsServer()
local DEFAULT_ANCESTORS = {workspace, game:GetService("Players")}


local renderId = 0
local function NextRenderName(): string
	renderId += 1
	return "ComponentRender" .. tostring(renderId)
end


local function InvokeExtensionFn(component, extensionList, fnName: string)
	for _,extension in ipairs(extensionList) do
		local fn = extension[fnName]
		if type(fn) == "function" then
		 return fn(component)
		end
	end	
			
	return ""
end
		
		


--[=[
	@class Component

	Bind components to Roblox instances using the Component class and CollectionService tags.
]=]
local Component = {}
Component.__index = Component


--[=[
	@param config ComponentConfig
	@return ComponentClass

	Create a new custom Component class.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})
	```

	A full example might look like this:

	```lua
	local MyComponent = Component.new({
		Tag = "MyComponent",
		Ancestors = {workspace},
		Extensions = {Logger}, -- See Logger example within the example for the Extension type
	})

	local AnotherComponent = require(somewhere.AnotherComponent)

	-- Optional if UpdateRenderStepped should use BindToRenderStep:
	MyComponent.RenderPriority = Enum.RenderPriority.Camera.Value

	function MyComponent:Construct()
		self.MyData = "Hello"
	end

	function MyComponent:Start()
		local another = self:GetComponent(AnotherComponent)
		another:DoSomething()
	end

	function MyComponent:Stop()
		self.MyData = "Goodbye"
	end

	function MyComponent:HeartbeatUpdate(dt)
	end

	function MyComponent:SteppedUpdate(dt)
	end
	
	function MyComponent:RenderSteppedUpdate(dt)
	end
	```
]=]
function Component.new(config: ComponentConfig)
	local customComponent = {}
	customComponent.__index = customComponent
	customComponent.__tostring = function()
		return "Component<" .. config.Tag .. ">"
	end
	customComponent._ancestors = config.Ancestors or DEFAULT_ANCESTORS
	customComponent._instancesToComponents = {}
	customComponent._components = {}
	customComponent._trove = Trove.new()
	customComponent._extensions = config.Extensions or {}
	customComponent._started = false
	customComponent.Tag = config.Tag
	customComponent.Started = customComponent._trove:Construct(Signal)
	customComponent.Stopped = customComponent._trove:Construct(Signal)
	setmetatable(customComponent, Component)
	customComponent:_setup()
	return customComponent
end


--[=[
	@param instance Instance
	@param componentClass ComponentClass
	@return Component?

	Gets an instance of a component class given the Roblox instance
	and the component class. Returns `nil` if not found.

	```lua
	local MyComponent = require(somewhere.MyComponent)

	local myComponentInstance = Component.FromInstance(workspace.SomeInstance, MyComponent)
	```
]=]
function Component.FromInstance(instance: Instance, componentClass)
	return componentClass._instancesToComponents[instance]
end


function Component:_instantiate(instance: Instance)
	local component = setmetatable({}, self)
	component.Instance = instance
		
	local shouldCreate = InvokeExtensionFn(component, self._extensions, "ShouldCreate")
				
	if not shouldCreate then
		-- Cleanup:
		component.Instance = nil
		return nil			
	end
	
				InvokeExtensionFn(component, self._extensions, "Constructing")
	if type(component.Construct) == "function" then
		component:Construct()
	end
	InvokeExtensionFn(component, self._extensions, "Constructed")
	return component
end


function Component:_setup()
	
	local watchingInstances = {}
	
	local function StartComponent(component)
		InvokeExtensionFn(component, self._extensions, "Starting")
		component:Start()
		InvokeExtensionFn(component, self._extensions, "Started")
		local hasHeartbeatUpdate = typeof(component.HeartbeatUpdate) == "function"
		local hasSteppedUpdate = typeof(component.SteppedUpdate) == "function"
		local hasRenderSteppedUpdate = typeof(component.RenderSteppedUpdate) == "function"
		if hasHeartbeatUpdate then
			component._heartbeatUpdate = RunService.Heartbeat:Connect(function(dt)
				component:HeartbeatUpdate(dt)
			end)
		end
		if hasSteppedUpdate then
			component._steppedUpdate = RunService.Stepped:Connect(function(_, dt)
				component:SteppedUpdate(dt)
			end)
		end
		if hasRenderSteppedUpdate and not IS_SERVER then
			if component.RenderPriority then
				self._renderName = NextRenderName()
				RunService:BindToRenderStep(self._renderName, component.RenderPriority, function(dt)
					component:RenderSteppedUpdate(dt)
				end)
			else
				component._renderSteppedUpdate = RunService.RenderStepped:Connect(function(dt)
					component:RenderSteppedUpdate(dt)
				end)
			end
		end
		component._started = true
		self.Started:Fire(component)
	end
	
	local function StopComponent(component)
		if component._heartbeatUpdate then
			component._heartbeatUpdate:Disconnect()
		end
		if component._steppedUpdate then
			component._steppedUpdate:Disconnect()
		end
		if component._renderSteppedUpdate then
			component._renderSteppedUpdate:Disconnect()
		elseif component._renderName then
			RunService:UnbindFromRenderStep(self._renderName)
		end
		InvokeExtensionFn(component, self._extensions, "Stopping")
		component:Stop()
		InvokeExtensionFn(component, self._extensions, "Stopped")
		self.Stopped:Fire(component)
	end
	
	local function TryConstructComponent(instance)
		if self._instancesToComponents[instance] then return end
		local component = self:_instantiate(instance)
		if not component then return end
					
		self._instancesToComponents[instance] = component
		table.insert(self._components, component)
		task.defer(function()
			if self._instancesToComponents[instance] == component then
				StartComponent(component)
			end
		end)
	end
	
	local function TryDeconstructComponent(instance)
		local component = self._instancesToComponents[instance]
		if not component then return end
		self._instancesToComponents[instance] = nil
		local index = table.find(self._components, component)
		if index then
			local n = #self._components
			self._components[index] = self._components[n]
			self._components[n] = nil
		end
		if component._started then
			task.spawn(StopComponent, component)
		end
	end
	
	local function StartWatchingInstance(instance)
		if watchingInstances[instance] then return end
		local function IsInAncestorList(): boolean
			for _,parent in ipairs(self._ancestors) do
				if instance:IsDescendantOf(parent) then
					return true
				end
			end
			return false
		end
		local ancestryChangedHandle = self._trove:Connect(instance.AncestryChanged, function(_, parent)
			if parent and IsInAncestorList() then
				TryConstructComponent(instance)
			else
				TryDeconstructComponent(instance)
			end
		end)
		watchingInstances[instance] = ancestryChangedHandle
		if IsInAncestorList() then
			TryConstructComponent(instance)
		end
	end
	
	local function InstanceTagged(instance: Instance)
		StartWatchingInstance(instance)
	end
	
	local function InstanceUntagged(instance: Instance)
		local watchHandle = watchingInstances[instance]
		if watchHandle then
			watchHandle:Disconnect()
			watchingInstances[instance] = nil
		end
		TryDeconstructComponent(instance)
	end
	
	self._trove:Connect(CollectionService:GetInstanceAddedSignal(self.Tag), InstanceTagged)
	self._trove:Connect(CollectionService:GetInstanceRemovedSignal(self.Tag), InstanceUntagged)
	
	local tagged = CollectionService:GetTagged(self.Tag)
	for _,instance in ipairs(tagged) do
		task.defer(InstanceTagged, instance)
	end
	
end


--[=[
	`Construct` is called before the component is started, and should be used
	to construct the component instance.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})

	function MyComponent:Construct()
		self.SomeData = 32
		self.OtherStuff = "HelloWorld"
	end
	```
]=]
function Component:Construct()
end


--[=[
	`Start` is called when the component is started. At this point in time, it
	is safe to grab other components also bound to the same instance.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})
	local AnotherComponent = require(somewhere.AnotherComponent)

	function MyComponent:Start()
		-- e.g., grab another component:
		local another = self:GetComponent(AnotherComponent)
	end
	```
]=]
function Component:Start()
end


--[=[
	`Stop` is called when the component is stopped. This occurs either when the
	bound instance is removed from one of the whitelisted ancestors _or_ when
	the matching tag is removed from the instance. This also means that the
	instance _might_ be destroyed, and thus it is not safe to continue using
	the bound instance (e.g. `self.Instance`) any longer.

	This should be used to clean up the component.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})

	function MyComponent:Stop()
		self.SomeStuff:Destroy()
	end
	```
]=]
function Component:Stop()
end


--[=[
	@param componentClass ComponentClass
	@return Component?

	Retrieves another component instance bound to the same
	Roblox instance.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})
	local AnotherComponent = require(somewhere.AnotherComponent)

	function MyComponent:Start()
		local another = self:GetComponent(AnotherComponent)
	end
	```
]=]
function Component:GetComponent(componentClass)
	return componentClass._instancesToComponents[self.Instance]
end


--[=[
	@function HeartbeatUpdate
	@param dt number
	@within Component

	If this method is present on a component, then it will be
	automatically connected to `RunService.Heartbeat`.

	:::note Method
	This is a method, not a function. This is a limitation
	of the documentation tool which should be fixed soon.
	:::
	
	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})
	
	function MyComponent:HeartbeatUpdate(dt)
	end
	```
]=]
--[=[
	@function SteppedUpdate
	@param dt number
	@within Component

	If this method is present on a component, then it will be
	automatically connected to `RunService.Stepped`.

	:::note Method
	This is a method, not a function. This is a limitation
	of the documentation tool which should be fixed soon.
	:::
	
	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})
	
	function MyComponent:SteppedUpdate(dt)
	end
	```
]=]
--[=[
	@function RenderSteppedUpdate
	@param dt number
	@within Component
	@client

	If this method is present on a component, then it will be
	automatically connected to `RunService.RenderStepped`. If
	the `[Component].RenderPriority` field is found, then the
	component will instead use `RunService:BindToRenderStep()`
	to bind the function.

	:::note Method
	This is a method, not a function. This is a limitation
	of the documentation tool which should be fixed soon.
	:::
	
	```lua
	-- Example that uses `RunService.RenderStepped` automatically:

	local MyComponent = Component.new({Tag = "MyComponent"})
	
	function MyComponent:RenderSteppedUpdate(dt)
	end
	```
	```lua
	-- Example that uses `RunService:BindToRenderStep` automatically:
	
	local MyComponent = Component.new({Tag = "MyComponent"})

	-- Defining a RenderPriority will force the component to use BindToRenderStep instead
	MyComponent.RenderPriority = Enum.RenderPriority.Camera.Value
	
	function MyComponent:RenderSteppedUpdate(dt)
	end
	```
]=]


function Component:Destroy()
	self._trove:Destroy()
end


return Component
