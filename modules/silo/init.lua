--!strict

-- Silo
-- Stephen Leitnick
-- April 29, 2022


--[=[
	@within Silo
	@type State<S> {[string]: any}
	Represents state.
]=]
export type State<S> = S & {[string]: any}

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
	Payload: A,
}

local Util = require(script.Util)
local TableWatcher = require(script.TableWatcher)

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
function Silo.new<S>(defaultState: State<S>, modifiers: {Modifier<S>}?)

	local self = setmetatable({}, Silo)

	self._State = Util.DeepFreeze(Util.DeepCopy(defaultState))
	self._Modifiers = {}
	self._Dispatching = false
	self._Parent = self
	self._Subscribers = {}

	self.Actions = {}

	-- Create modifiers and action creators:
	for actionName,modifier in pairs(modifiers or {}) do

		self._Modifiers[actionName] = function(state: State<S>, payload: any)
			-- Create a watcher to virtually watch for state mutations:
			local watcher = TableWatcher(state)
			modifier(watcher, payload)
			-- Apply state mutations into new state table:
			return watcher()
		end

		self.Actions[actionName] = function(payload)
			return {
				Name = actionName,
				Payload = payload,
			}
		end

	end

	return self

end

--[=[
	@param silos {Silo}
	@return Silo
	Constructs a new silo as a combination of other silos.
]=]
function Silo.combine<S>(silos, initialState: State<S>?)

	-- Combine state:
	local state = {}
	for name,silo in pairs(silos) do
		if silo._Dispatching then
			error("cannot combine silos from a modifier", 2)
		end
		state[name] = silo:GetState()
	end

	local combinedSilo = Silo.new(Util.Extend(state, initialState or {}))

	-- Combine modifiers and actions:
	for name,silo in pairs(silos) do
		silo._Parent = combinedSilo
		for actionName,modifier in pairs(silo._Modifiers) do
			-- Prefix action name to keep it unique:
			local fullActionName = name .. "/" .. actionName
			combinedSilo._Modifiers[fullActionName] = function(s, payload)
				-- Extend the top-level state from the sub-silo state modification:
				return Util.Extend(s, {
					[name] = modifier((s :: {[string]: any})[name], payload)
				})
			end
		end
		for actionName in pairs(silo.Actions) do
			-- Update the action creator to include the correct prefixed action name:
			local fullActionName = name .. "/" .. actionName
			silo.Actions[actionName] = function(p)
				return {
					Name = fullActionName,
					Payload = p,
				}
			end
		end
	end

	return combinedSilo

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

	-- Find and invoke the modifier to modify current state:
	self._Dispatching = true
	local oldState = self._State
	local newState = oldState
	local modifier = self._Modifiers[action.Name]
	if modifier then
		newState = modifier(newState, action.Payload)
	end
	self._Dispatching = false

	-- State changed:
	if newState ~= oldState then

		self._State = Util.DeepFreeze(newState)

		-- Notify subscribers of state change:
		for _,subscriber in ipairs(self._Subscribers) do
			subscriber(newState, oldState)
		end
		
	end

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

	if self._Dispatching then
		error("cannot subscribe from within a modifier", 2)
	end
	if self._Parent ~= self then
		error("can only subscribe on top-level silo", 2)
	end
	if table.find(self._Subscribers, subscriber) then
		error("cannot subscribe same function more than once", 2)
	end

	table.insert(self._Subscribers, subscriber)

	-- Unsubscribe:
	return function()
		local index = table.find(self._Subscribers, subscriber)
		if not index then return end
		table.remove(self._Subscribers, index)
	end

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
		if newValue == value then return end
		value = newValue
		onChange(value)
	end)

	-- Call initial onChange after subscription to verify subscription didn't fail:
	onChange(value)

	return unsubscribe

end

return Silo
