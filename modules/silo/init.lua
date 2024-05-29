-- Silo
-- Stephen Leitnick
-- April 29, 2022

--[=[
	@within Silo
	@type State<S> {[string]: any}
	Represents state.
]=]
export type State<S> = S & { [string]: any }

--[=[
	@within Silo
	@type Modifier<S> (State<S>, any) -> ()
	A function that modifies state.
]=]
export type Modifier<S> = (State<S>, any) -> ()

--[=[
	@within Silo
	@interface Action<A>
	.Name string
	.Payload A
	Actions are passed to `Dispatch`. However, typically actions are
	never constructed by hand. Use a silo's Actions table to generate
	these actions.
]=]
type Action<A> = {
	Name: string,
	Payload: { A },
}

export type Silo<S, A> = {
	Actions: { [string]: <A>(value: A) -> () },

	GetState: (self: Silo<S, A>) -> State<S>,
	Dispatch: (self: Silo<S, A>, action: Action<A>) -> (),
	ResetToDefaultState: (self: Silo<S, A>) -> (),
	Subscribe: (self: Silo<S, A>, subscriber: (newState: State<S>, oldState: State<S>) -> ()) -> () -> (),
	Watch: <T>(self: Silo<S, A>, selector: (State<S>) -> T, onChange: (T) -> ()) -> () -> (),
}

local TableWatcher = require(script.TableWatcher)
local Util = require(script.Util)

--[=[
	@class Silo
	A Silo is a state container, inspired by Redux slices and
	designed for Roblox developers.
]=]
local Silo = {}
Silo.__index = Silo

--[=[
	@return Silo
	Create a Silo.

	```lua
	local statsSilo = Silo.new({
		-- Initial state:
		Kills = 0,
		Deaths = 0,
		Points = 0,
	}, {
		-- Modifiers are functions that modify the state:
		SetKills = function(state, kills)
			state.Kills = kills
		end,
		AddPoints = function(state, points)
			state.Points += points
		end,
	})

	-- Use Actions to modify the state:
	statsSilo:Dispatch(statsSilo.Actions.SetKills(10))

	-- Use GetState to get the current state:
	print("Kills", statsSilo:GetState().Kills)
	```

	From the above example, note how the modifier functions were transformed
	into functions that can be called from `Actions` with just the single
	payload (no need to pass state). The `SetKills` modifier is then used
	as the `SetKills` action to be dispatched.
]=]
function Silo.new<S, A>(defaultState: State<S>, modifiers: { [string]: Modifier<S> }?): Silo<S, A>
	local self = setmetatable({}, Silo)

	self._DefaultState = Util.DeepFreeze(Util.DeepCopy(defaultState))
	self._State = Util.DeepFreeze(Util.DeepCopy(defaultState))
	self._Modifiers = {} :: { [string]: any }
	self._Dispatching = false
	self._Parent = self
	self._StateSubscribers = {}
	self._DispatchSubscribers = {}

	self.Actions = {}

	-- Create modifiers and action creators:
	if modifiers then
		for actionName, modifier in modifiers do
			self._Modifiers[actionName] = function(state: State<S>, ...: any)
				-- Create a watcher to virtually watch for state mutations:
				local watcher = TableWatcher(state)
				modifier(watcher :: any, ...)
				-- Apply state mutations into new state table:
				return watcher()
			end

			self.Actions[actionName] = function(...: any)
				return {
					Name = actionName,
					Payload = { ... },
				}
			end
		end
	end

	return self
end

--[=[
	@param silos {Silo}
	@return Silo
	Constructs a new silo as a combination of other silos.
]=]
function Silo.combine<S, A>(silos: { [string]: Silo<unknown, unknown> }, initialState: State<S>?): Silo<S, A>
	-- Combine state:
	local state = {}
	for name, silo in silos do
		if silo._Dispatching then
			error("cannot combine silos from a modifier", 2)
		end
		state[name] = silo:GetState()
	end

	local combinedSilo = Silo.new(Util.Extend(state, initialState or {}))

	-- Combine modifiers and actions:
	for name, silo in silos do
		silo._Parent = combinedSilo
		for actionName, modifier in silo._Modifiers do
			-- Prefix action name to keep it unique:
			local fullActionName = `{name}/{actionName}`
			combinedSilo._Modifiers[fullActionName] = function(s, ...: any)
				-- Extend the top-level state from the sub-silo state modification:
				return Util.Extend(s, {
					[name] = modifier((s :: { [string]: any })[name], ...),
				})
			end
		end
		for actionName in silo.Actions do
			if combinedSilo.Actions[actionName] ~= nil then
				error(`duplicate action name {actionName} found when combining silos`, 2)
			end
			-- Update the action creator to include the correct prefixed action name:
			local fullActionName = `{name}/{actionName}`
			silo.Actions[actionName] = function(...: any)
				return {
					Name = fullActionName,
					Payload = { ... },
				}
			end
			combinedSilo.Actions[actionName] = silo.Actions[actionName]
		end
	end

	return combinedSilo
end

function Silo:_subscribeInternal<T>(subscriberTbl: { T }, subscriber: T): () -> ()
	if self._Dispatching then
		error("cannot subscribe from within a modifier", 2)
	end
	if self._Parent ~= self then
		error("can only subscribe on top-level silo", 2)
	end
	if table.find(subscriberTbl, subscriber) then
		error("cannot subscribe same function more than once", 2)
	end

	table.insert(subscriberTbl, subscriber)

	return function()
		local index = table.find(subscriberTbl, subscriber)
		if not index then
			return
		end
		table.remove(subscriberTbl, index)
	end
end

--[=[
	Get the current state.

	```lua
	local state = silo:GetState()
	```
]=]
function Silo:GetState<S>(): State<S>
	if self._Parent ~= self then
		error("can only get state from top-level silo", 2)
	end
	return self._State
end

--[=[
	Dispatch an action.

	```lua
	silo:Dispatch(silo.Actions.DoSomething("something"))
	```
]=]
function Silo:Dispatch<A>(action: Action<A>)
	if self._Dispatching then
		error("cannot dispatch from a modifier", 2)
	end
	if self._Parent ~= self then
		error("can only dispatch from top-level silo", 2)
	end

	-- Notify dispatch subscribers of action dispatch:
	for _, subscriber in self._DispatchSubscribers do
		subscriber(action)
	end

	-- Find and invoke the modifier to modify current state:
	self._Dispatching = true
	local oldState = self._State
	local newState = oldState
	local modifier = self._Modifiers[action.Name]
	if modifier then
		newState = modifier(newState, table.unpack(action.Payload))
	end
	self._Dispatching = false

	-- State changed:
	if newState ~= oldState then
		self._State = Util.DeepFreeze(newState)

		-- Notify state subscribers of state change:
		for _, subscriber in self._StateSubscribers do
			subscriber(newState, oldState)
		end
	end
end

--[=[
	Subscribe a function to receive all action dispatches. Most useful for
	replicating state between two identical silos running on client and
	server without ever directly touching state.

	Returns an unsubscribe function. Call the function to unsubscribe.

	```lua
	local unsubscribe = silo:OnDispatch(function(action)
		-- Do something
	end)

	-- Later on, if desired, disconnect the subscription by calling unsubscribe:
	unsubscribe()
	```
]=]
function Silo:OnDispatch<A>(subscriber: (action: Action<A>) -> ()): () -> ()
	return self:_subscribeInternal(self._DispatchSubscribers, subscriber)
end

--[=[
	Subscribe a function to receive all state updates, including
	initial state (subscriber is called immediately).

	Returns an unsubscribe function. Call the function to unsubscribe.

	```lua
	local unsubscribe = silo:Subscribe(function(newState, oldState)
		-- Do something
	end)

	-- Later on, if desired, disconnect the subscription by calling unsubscribe:
	unsubscribe()
	```
]=]
function Silo:Subscribe<S>(subscriber: (newState: State<S>, oldState: State<S>) -> ()): () -> ()
	return self:_subscribeInternal(self._StateSubscribers, subscriber)
end

--[=[
	Watch a specific value within the state, which is selected by the
	`selector` function. The initial value, and any subsequent changes
	grabbed by the selector, will be passed to the `onChange` function.

	Just like `Subscribe`, a function is returned that can be used
	to unsubscribe (i.e. stop watching).

	```lua
	local function SelectPoints(state)
		return state.Statistics.Points
	end

	local unsubscribe = silo:Watch(SelectPoints, function(points)
		print("Points", points)
	end)
	```
]=]
function Silo:Watch<S, T>(selector: (State<S>) -> T, onChange: (T) -> ()): () -> ()
	local value = selector(self:GetState())

	local unsubscribe = self:Subscribe(function(state)
		local newValue = selector(state)
		if newValue == value then
			return
		end
		value = newValue
		onChange(value)
	end)

	-- Call initial onChange after subscription to verify subscription didn't fail:
	onChange(value)

	return unsubscribe
end

--[=[
	Reset the state to the default state that was given in the constructor.

	```lua
	local silo = Silo.new({
		Points = 0,
	}, {
		SetPoints = function(state, points)
			state.Points = points
		end
	})

	silo:Dispatch(silo.Actions.SetPoints(10))

	print(silo:GetState().Points) -- 10

	silo:ResetToDefaultState()

	print(silo:GetState().Points) -- 0
	```
]=]
function Silo:ResetToDefaultState()
	if self._Dispatching then
		error("cannot reset state from within a modifier", 2)
	end

	if self._Parent ~= self then
		error("can only reset state on top-level silo", 2)
	end

	local oldState = self._State

	if self._DefaultState ~= oldState then
		self._State = Util.DeepFreeze(Util.DeepCopy(self._DefaultState))

		for _, subscriber in self._StateSubscribers do
			subscriber(self._State, oldState)
		end
	end
end

return {
	new = Silo.new,
	combine = Silo.combine,
}
