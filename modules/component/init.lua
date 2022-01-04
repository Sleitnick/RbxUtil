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
	@type ExtensionShouldFn (component) -> boolean
	@within Component
]=]
type ExtensionShouldFn = (any) -> boolean


--[=[
	@interface Extension
	@within Component
	.ShouldExtend ExtensionShouldFn?
	.ShouldConstruct ExtensionShouldFn?
	.Constructing ExtensionFn?
	.Constructed ExtensionFn?
	.Starting ExtensionFn?
	.Started ExtensionFn?
	.Stopping ExtensionFn?
	.Stopped ExtensionFn?

	An extension allows the ability to extend the behavior of
	components. This is useful for adding injection systems or
	extending the behavior of components by wrapping around
	component lifecycle methods.

	The `ShouldConstruct` function can be used to indicate
	if the component should actually be created. This must
	return `true` or `false`. A component with multiple
	`ShouldConstruct` extension functions must have them _all_
	return `true` in order for the component to be constructed.
	The `ShouldConstruct` function runs _before_ all other
	extension functions and component lifecycle methods.

	The `ShouldExtend` function can be used to indicate if
	the extension itself should be used. This can be used in
	order to toggle an extension on/off depending on whatever
	logic is appropriate. If no `ShouldExtend` function is
	provided, the extension will always be used if provided
	as an extension to the component.

	As an example, an extension could be created to simply log
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

	Sometimes it is useful for an extension to control whether or
	not a component should be constructed. For instance, if a
	component on the client should only be instantiated for the
	local player, an extension might look like this, assuming the
	instance has an attribute linking it to the player's UserId:
	```lua
	local player = game:GetService("Players").LocalPlayer

	local OnlyLocalPlayer = {}
	function OnlyLocalPlayer.ShouldConstruct(component)
		local ownerId = component.Instance:GetAttribute("OwnerId")
		return ownerId == player.UserId
	end

	local MyComponent = Component.new({Tag = "MyComponent", Extensions = {OnlyLocalPlayer}})
	```

	It can also be useful for an extension itself to turn on/off
	depending on various contexts. For example, let's take the
	Logger from the first example, and only use that extension
	if the bound instance has a Log attribute set to `true`:
	```lua
	function Logger.ShouldExtend(component)
		return component.Instance:GetAttribute("Log") == true
	end
	```
]=]
type Extension = {
	ShouldExtend: ExtensionShouldFn?,
	ShouldConstruct: ExtensionShouldFn?,
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
local Symbol = require(script.Parent.Symbol)
local Trove = require(script.Parent.Trove)

local IS_SERVER = RunService:IsServer()
local DEFAULT_ANCESTORS = {workspace, game:GetService("Players")}

-- Symbol keys:
local KEY_ANCESTORS = Symbol("Ancestors")
local KEY_INST_TO_COMPONENTS = Symbol("InstancesToComponents")
local KEY_COMPONENTS = Symbol("Components")
local KEY_TROVE = Symbol("Trove")
local KEY_EXTENSIONS = Symbol("Extensions")
local KEY_ACTIVE_EXTENSIONS = Symbol("ActiveExtensions")
local KEY_STARTED = Symbol("Started")


local renderId = 0
local function NextRenderName(): string
	renderId += 1
	return "ComponentRender" .. tostring(renderId)
end


local function InvokeExtensionFn(component, fnName: string)
	for _,extension in ipairs(component[KEY_ACTIVE_EXTENSIONS]) do
		local fn = extension[fnName]
		if type(fn) == "function" then
			fn(component)
		end
	end
end


local function ShouldConstruct(component): boolean
	for _,extension in ipairs(component[KEY_ACTIVE_EXTENSIONS]) do
		local fn = extension.ShouldConstruct
		if type(fn) == "function" then
			local shouldConstruct = fn(component)
			if not shouldConstruct then
				return false
			end
		end
	end
	return true
end


local function GetActiveExtensions(component, extensionList)
	local activeExtensions = table.create(#extensionList)
	local allActive = true
	for _,extension in ipairs(extensionList) do
		local fn = extension.ShouldExtend
		local shouldExtend = type(fn) ~= "function" or not not fn(component)
		if shouldExtend then
			table.insert(activeExtensions, extension)
		else
			allActive = false
		end
	end
	return if allActive then extensionList else activeExtensions
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
	customComponent[KEY_ANCESTORS] = config.Ancestors or DEFAULT_ANCESTORS
	customComponent[KEY_INST_TO_COMPONENTS] = {}
	customComponent[KEY_COMPONENTS] = {}
	customComponent[KEY_TROVE] = Trove.new()
	customComponent[KEY_EXTENSIONS] = config.Extensions or {}
	customComponent[KEY_STARTED] = false
	customComponent.Tag = config.Tag
	customComponent.Started = customComponent[KEY_TROVE]:Construct(Signal)
	customComponent.Stopped = customComponent[KEY_TROVE]:Construct(Signal)
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
	return componentClass[KEY_INST_TO_COMPONENTS][instance]
end


function Component:_instantiate(instance: Instance)
	local component = setmetatable({}, self)
	component.Instance = instance
	component[KEY_ACTIVE_EXTENSIONS] = GetActiveExtensions(component, self[KEY_EXTENSIONS])
	if not ShouldConstruct(component) then
		return nil
	end
	InvokeExtensionFn(component, "Constructing")
	if type(component.Construct) == "function" then
		component:Construct()
	end
	InvokeExtensionFn(component, "Constructed")
	return component
end


function Component:_setup()
	
	local watchingInstances = {}
	
	local function StartComponent(component)
		InvokeExtensionFn(component, "Starting")
		component:Start()
		InvokeExtensionFn(component, "Started")
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
		component[KEY_STARTED] = true
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
		InvokeExtensionFn(component, "Stopping")
		component:Stop()
		InvokeExtensionFn(component, "Stopped")
		self.Stopped:Fire(component)
	end
	
	local function TryConstructComponent(instance)
		if self[KEY_INST_TO_COMPONENTS][instance] then return end
		local component = self:_instantiate(instance)
		if not component then
			return
		end
		self[KEY_INST_TO_COMPONENTS][instance] = component
		table.insert(self[KEY_COMPONENTS], component)
		task.defer(function()
			if self[KEY_INST_TO_COMPONENTS][instance] == component then
				StartComponent(component)
			end
		end)
	end
	
	local function TryDeconstructComponent(instance)
		local component = self[KEY_INST_TO_COMPONENTS][instance]
		if not component then return end
		self[KEY_INST_TO_COMPONENTS][instance] = nil
		local components = self[KEY_COMPONENTS]
		local index = table.find(components, component)
		if index then
			local n = #components
			components[index] = components[n]
			components[n] = nil
		end
		if component[KEY_STARTED] then
			task.spawn(StopComponent, component)
		end
	end
	
	local function StartWatchingInstance(instance)
		if watchingInstances[instance] then return end
		local function IsInAncestorList(): boolean
			for _,parent in ipairs(self[KEY_ANCESTORS]) do
				if instance:IsDescendantOf(parent) then
					return true
				end
			end
			return false
		end
		local ancestryChangedHandle = self[KEY_TROVE]:Connect(instance.AncestryChanged, function(_, parent)
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
	
	self[KEY_TROVE]:Connect(CollectionService:GetInstanceAddedSignal(self.Tag), InstanceTagged)
	self[KEY_TROVE]:Connect(CollectionService:GetInstanceRemovedSignal(self.Tag), InstanceUntagged)
	
	local tagged = CollectionService:GetTagged(self.Tag)
	for _,instance in ipairs(tagged) do
		task.defer(InstanceTagged, instance)
	end
	
end


--[=[
	@return {Component}
	Gets a table array of all existing component objects. For example,
	if there was a component class linked to the "MyComponent" tag,
	and three Roblox instances in your game had that same tag, then
	calling `GetAll` would return the three component instances.

	```lua
	local MyComponent = Component.new({Tag = "MyComponent"})

	-- ...

	local components = MyComponent:GetAll()
	for _,component in ipairs(components) do
		component:DoSomethingHere()
	end
	```
]=]
function Component:GetAll()
	return self[KEY_COMPONENTS]
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
	return componentClass[KEY_INST_TO_COMPONENTS][self.Instance]
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
	self[KEY_TROVE]:Destroy()
end


return Component
