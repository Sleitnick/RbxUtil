-- Component
-- Stephen Leitnick
-- July 25, 2020

--[[

	Component.Auto(folder: Instance)
		-> Create components automatically from descendant modules of this folder
		-> Each module must have a '.Tag' string property
		-> Each module optionally can have '.RenderPriority' number property

	component = Component.FromTag(tag: string)
		-> Retrieves an existing component from the tag name

	Component.ObserveFromTag(tag: string, observer: (component: Component, trove: Trove) -> void): Trove

	component = Component.new(tag: string, class: table [, renderPriority: RenderPriority, requireComponents: {string}])
		-> Creates a new component from the tag name, class module, and optional render priority

	component:GetAll(): ComponentInstance[]
	component:GetFromInstance(instance: Instance): ComponentInstance | nil
	component:GetFromID(id: number): ComponentInstance | nil
	component:Filter(filterFunc: (comp: ComponentInstance) -> boolean): ComponentInstance[]
	component:WaitFor(instanceOrName: Instance | string [, timeout: number = 60]): Promise<ComponentInstance>
	component:Observe(instance: Instance, observer: (component: ComponentInstance, trove: Trove) -> void): Trove
	component:Destroy()

	component.Added(obj: ComponentInstance)
	component.Removed(obj: ComponentInstance)

	-----------------------------------------------------------------------

	A component class must look something like this:

		-- DEFINE
		local MyComponent = {}
		MyComponent.__index = MyComponent

		-- CONSTRUCTOR
		function MyComponent.new(instance)
			local self = setmetatable({}, MyComponent)
			return self
		end

		-- FIELDS AFTER CONSTRUCTOR COMPLETES
		MyComponent.Instance: Instance

		-- OPTIONAL LIFECYCLE HOOKS
		function MyComponent:Init() end                     -> Called right after constructor
		function MyComponent:Deinit() end                   -> Called right before deconstructor
		function MyComponent:HeartbeatUpdate(dt) ... end    -> Updates every heartbeat
		function MyComponent:SteppedUpdate(dt) ... end      -> Updates every physics step
		function MyComponent:RenderUpdate(dt) ... end       -> Updates every render step

		-- DESTRUCTOR
		function MyComponent:Destroy()
		end


	A component is then registered like so:

		local Component = require(Knit.Util.Component)
		local MyComponent = require(somewhere.MyComponent)
		local tag = "MyComponent"

		local myComponent = Component.new(tag, MyComponent)


	Components can be listened and queried:

		myComponent.Added:Connect(function(instanceOfComponent)
			-- New MyComponent constructed
		end)

		myComponent.Removed:Connect(function(instanceOfComponent)
			-- New MyComponent deconstructed
		end)

--]]


local Trove = require(script.Parent.Trove)
local Signal = require(script.Parent.Signal)
local Promise = require(script.Parent.Promise)
local TableUtil = require(script.Parent.TableUtil)

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IS_SERVER = RunService:IsServer()
local DEFAULT_WAIT_FOR_TIMEOUT = 60
local ATTRIBUTE_ID_NAME = "ComponentServerId"

-- Components will only work on instances parented under these descendants:
local DESCENDANT_WHITELIST = {workspace, Players}

--[=[
	@class Component
	Extends functionality of an instance based on the CollectionService tags of the instance.
]=]
local Component = {}
Component.__index = Component

local componentsByTag = {}

local componentByTagCreated = Signal.new()
local componentByTagDestroyed = Signal.new()


local function IsDescendantOfWhitelist(instance)
	for _,v in ipairs(DESCENDANT_WHITELIST) do
		if instance:IsDescendantOf(v) then
			return true
		end
	end
	return false
end


--[=[
	@param tag string
	@return Component?
	Returns a component previously constructed by the tag. Returns
	`nil` if no component is found.
]=]
function Component.FromTag(tag)
	return componentsByTag[tag]
end


--[=[
	@param tag string
	@param observer (component: Component, trove: Trove) -> nil
	@return Trove
	Observes the existence of a component.
]=]
function Component.ObserveFromTag(tag, observer)
	local trove = Trove.new()
	local observeTrove = trove:Construct(Trove)
	local function OnCreated(component)
		if component._tag == tag then
			observer(component, observeTrove)
		end
	end
	local function OnDestroyed(component)
		if component._tag == tag then
			observeTrove:Clean()
		end
	end
	do
		local component = Component.FromTag(tag)
		if component then
			task.spawn(OnCreated, component)
		end
	end
	trove:Add(componentByTagCreated:Connect(OnCreated))
	trove:Add(componentByTagDestroyed:Connect(OnDestroyed))
	return trove
end


--[=[
	@param parent Instance
	@return RBXScriptConnection

	Scans all descendants of `parent` and loads any ModuleScripts found, then
	calls `Component.new` on those loaded modules.

	Each component module class must have a `Tag` string property to map it
	to the proper tag.
]=]
function Component.Auto(parent)
	local function Setup(moduleScript)
		local m = require(moduleScript)
		assert(type(m) == "table", "Expected table for component")
		assert(type(m.Tag) == "string", "Expected .Tag property")
		Component.new(m.Tag, m, m.RenderPriority, m.RequiredComponents)
	end
	for _,v in ipairs(parent:GetDescendants()) do
		if v:IsA("ModuleScript") then
			Setup(v)
		end
	end
	return parent.DescendantAdded:Connect(function(v)
		if v:IsA("ModuleScript") then
			Setup(v)
		end
	end)
end


--[=[
	@param tag string
	@param class table
	@param renderPriority number?
	@param requireComponents {string}?
	@return Component

	Constructs a new component class.
]=]
function Component.new(tag, class, renderPriority, requireComponents)

	assert(type(tag) == "string", "Argument #1 (tag) should be a string; got " .. type(tag))
	assert(type(class) == "table", "Argument #2 (class) should be a table; got " .. type(class))
	assert(type(class.new) == "function", "Class must contain a .new constructor function")
	assert(type(class.Destroy) == "function", "Class must contain a :Destroy function")
	assert(componentsByTag[tag] == nil, "Component already bound to this tag")

	local self = setmetatable({}, Component)

	self._trove = Trove.new()
	self._lifecycleTrove = self._trove:Construct(Trove)
	self._tag = tag
	self._class = class
	self._objects = {}
	self._instancesToObjects = {}
	self._hasHeartbeatUpdate = (type(class.HeartbeatUpdate) == "function")
	self._hasSteppedUpdate = (type(class.SteppedUpdate) == "function")
	self._hasRenderUpdate = (type(class.RenderUpdate) == "function")
	self._hasInit = (type(class.Init) == "function")
	self._hasDeinit = (type(class.Deinit) == "function")
	self._renderPriority = renderPriority or Enum.RenderPriority.Last.Value
	self._requireComponents = requireComponents or {}
	self._lifecycle = false
	self._nextId = 0

	self.Added = self._trove:Construct(Signal)
	self.Removed = self._trove:Construct(Signal)

	local observeTrove = self._trove:Construct(Trove)

	local function ObserveTag()

		local function HasRequiredComponents(instance)
			for _,reqComp in ipairs(self._requireComponents) do
				local comp = Component.FromTag(reqComp)
				if comp:GetFromInstance(instance) == nil then
					return false
				end
			end
			return true
		end

		observeTrove:Connect(CollectionService:GetInstanceAddedSignal(tag), function(instance)
			if IsDescendantOfWhitelist(instance) and HasRequiredComponents(instance) then
				self:_instanceAdded(instance)
			end
		end)

		observeTrove:Connect(CollectionService:GetInstanceRemovedSignal(tag), function(instance)
			self:_instanceRemoved(instance)
		end)

		for _,reqComp in ipairs(self._requireComponents) do
			local comp = Component.FromTag(reqComp)
			observeTrove:Connect(comp.Added, function(obj)
				if CollectionService:HasTag(obj.Instance, tag) and HasRequiredComponents(obj.Instance) then
					self:_instanceAdded(obj.Instance)
				end
			end)
			observeTrove:Connect(comp.Removed, function(obj)
				if CollectionService:HasTag(obj.Instance, tag) then
					self:_instanceRemoved(obj.Instance)
				end
			end)
		end

		observeTrove:Add(function()
			self:_stopLifecycle()
			for instance in pairs(self._instancesToObjects) do
				self:_instanceRemoved(instance)
			end
		end)

		do
			for _,instance in ipairs(CollectionService:GetTagged(tag)) do
				if IsDescendantOfWhitelist(instance) and HasRequiredComponents(instance) then
					task.defer(function()
						self:_instanceAdded(instance)
					end)
				end
			end
		end

	end

	if #self._requireComponents == 0 then
		ObserveTag()
	else
		-- Only observe tag when all required components are available:
		local tagsReady = {}
		local function Check()
			for _,ready in pairs(tagsReady) do
				if not ready then
					return
				end
			end
			ObserveTag()
		end
		local function Cleanup()
			observeTrove:Clean()
		end
		for _,requiredComponent in ipairs(self._requireComponents) do
			tagsReady[requiredComponent] = false
		end
		for _,requiredComponent in ipairs(self._requireComponents) do
			self._trove:Add(Component.ObserveFromTag(requiredComponent, function(_component, trove)
				tagsReady[requiredComponent] = true
				Check()
				trove:Add(function()
					tagsReady[requiredComponent] = false
					Cleanup()
				end)
			end))
		end
	end

	componentsByTag[tag] = self
	componentByTagCreated:Fire(self)
	self._trove:Add(function()
		componentsByTag[tag] = nil
		componentByTagDestroyed:Fire(self)
	end)

	return self

end


function Component:_startHeartbeatUpdate()
	local all = self._objects
	self._heartbeatUpdate = RunService.Heartbeat:Connect(function(dt)
		for _,v in ipairs(all) do
			v:HeartbeatUpdate(dt)
		end
	end)
	self._lifecycleTrove:Add(self._heartbeatUpdate)
end


function Component:_startSteppedUpdate()
	local all = self._objects
	self._steppedUpdate = RunService.Stepped:Connect(function(_, dt)
		for _,v in ipairs(all) do
			v:SteppedUpdate(dt)
		end
	end)
	self._lifecycleTrove:Add(self._steppedUpdate)
end


function Component:_startRenderUpdate()
	local all = self._objects
	self._renderName = (self._tag .. "RenderUpdate")
	RunService:BindToRenderStep(self._renderName, self._renderPriority, function(dt)
		for _,v in ipairs(all) do
			v:RenderUpdate(dt)
		end
	end)
	self._lifecycleTrove:Add(function()
		RunService:UnbindFromRenderStep(self._renderName)
	end)
end


function Component:_startLifecycle()
	self._lifecycle = true
	if self._hasHeartbeatUpdate then
		self:_startHeartbeatUpdate()
	end
	if self._hasSteppedUpdate then
		self:_startSteppedUpdate()
	end
	if self._hasRenderUpdate then
		self:_startRenderUpdate()
	end
end


function Component:_stopLifecycle()
	self._lifecycle = false
	self._lifecycleTrove:Clean()
end


function Component:_instanceAdded(instance)
	if self._instancesToObjects[instance] then return end
	if not self._lifecycle then
		self:_startLifecycle()
	end
	self._nextId = (self._nextId + 1)
	local id = (self._tag .. tostring(self._nextId))
	if IS_SERVER then
		instance:SetAttribute(ATTRIBUTE_ID_NAME, id)
	end
	local obj = self._class.new(instance)
	obj.Instance = instance
	obj._id = id
	self._instancesToObjects[instance] = obj
	table.insert(self._objects, obj)
	if self._hasInit then
		task.defer(function()
			if self._instancesToObjects[instance] ~= obj then return end
			obj:Init()
		end)
	end
	self.Added:Fire(obj)
	return obj
end


function Component:_instanceRemoved(instance)
	if not self._instancesToObjects[instance] then return end
	self._instancesToObjects[instance] = nil
	for i,obj in ipairs(self._objects) do
		if obj.Instance == instance then
			if self._hasDeinit then
				obj:Deinit()
			end
			if IS_SERVER and instance.Parent and instance:GetAttribute(ATTRIBUTE_ID_NAME) ~= nil then
				instance:SetAttribute(ATTRIBUTE_ID_NAME, nil)
			end
			self.Removed:Fire(obj)
			obj:Destroy()
			obj._destroyed = true
			TableUtil.SwapRemove(self._objects, i)
			break
		end
	end
	if #self._objects == 0 and self._lifecycle then
		self:_stopLifecycle()
	end
end


--[=[
	@return {componentInstances}
	Returns an array of all component instances.
]=]
function Component:GetAll()
	return TableUtil.Copy(self._objects)
end


--[=[
	@param instance Instance
	@return component?
	Returns a component instance from the given Roblox instance.
]=]
function Component:GetFromInstance(instance)
	return self._instancesToObjects[instance]
end


--[=[
	@param id string
	@return component?
	Returns a component instance from the given ID.
]=]
function Component:GetFromID(id)
	for _,v in ipairs(self._objects) do
		if v._id == id then
			return v
		end
	end
	return nil
end


--[=[
	@param filterFn (value: componentInstance) -> keep: boolean
	@return {componentInstance}
	Filters out all component instances based on the `filterFn` function predicate.
]=]
function Component:Filter(filterFn)
	return TableUtil.Filter(self._objects, filterFn)
end


--[=[
	@param instance Instance
	@param timeout number?
	@return Promise<componentInstance>
	Waits for a component instance to exist on the given Roblox instance.
]=]
function Component:WaitFor(instance, timeout)
	local isName = (type(instance) == "string")
	local function IsInstanceValid(obj)
		return ((isName and obj.Instance.Name == instance) or ((not isName) and obj.Instance == instance))
	end
	for _,obj in ipairs(self._objects) do
		if IsInstanceValid(obj) then
			return Promise.resolve(obj)
		end
	end
	local lastObj = nil
	return Promise.fromEvent(self.Added, function(obj)
		lastObj = obj
		return IsInstanceValid(obj)
	end):andThen(function()
		return lastObj
	end):timeout(timeout or DEFAULT_WAIT_FOR_TIMEOUT)
end


--[=[
	@param instance Instance
	@param observer (component: componentInstance, trove: Trove) -> nil
	@return Trove
	Observes the existence of a component instance on the given Roblox instance.
]=]
function Component:Observe(instance, observer)
	local trove = Trove.new()
	local observeTrove = trove:Construct(Trove)
	trove:Connect(self.Added, function(obj)
		if obj.Instance == instance then
			observer(obj, observeTrove)
		end
	end)
	trove:Connect(self.Removed, function(obj)
		if obj.Instance == instance then
			observeTrove:Clean()
		end
	end)
	for _,obj in ipairs(self._objects) do
		if obj.Instance == instance then
			task.spawn(observer, obj, observeTrove)
			break
		end
	end
	return trove
end


--[=[
	Destroys the component class.
]=]
function Component:Destroy()
	self._trove:Destroy()
end


return Component
