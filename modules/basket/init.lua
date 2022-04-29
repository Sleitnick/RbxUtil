-- Basket
-- Stephen Leitnick
-- April 29, 2022


local Util = require(script.Util)
local TableWatcher = require(script.TableWatcher)

local Basket = {}
Basket.__index = Basket

function Basket.new(defaultState, reducers)
	local self = setmetatable({}, Basket)
	self._State = Util.DeepCopy(defaultState)
	self._Reducers = reducers or {}
	self._Dispatching = false
	self._Subscribers = {}
	self.Actions = {}
	for actionName,reducer in pairs(self._Reducers) do
		self._Reducers[actionName] = function(state, payload)
			local watcher = TableWatcher(state)
			reducer(watcher, payload)
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

function Basket:GetState()
	return self._State
end

function Basket:Dispatch(action)
	if self._Dispatching then
		error("cannot dispatch from a reducer", 2)
	end
	self._Dispatching = true
	local oldState = self._State
	local newState = oldState
	local reducer = self._Reducers[action.Name]
	if reducer then
		newState = reducer(newState, action.Payload)
	end
	self._State = newState
	self._Dispatching = false
	for _,subscriber in ipairs(self._Subscribers) do
		subscriber(newState, oldState)
	end
end

function Basket:Subscribe(subscriber)
	if self._Dispatching then
		error("cannot subscribe from within a reducer", 2)
	end
	if table.find(self._Subscribers, subscriber) then
		error("cannot subscribe same function more than once", 2)
	end
	table.insert(self._Subscribers, subscriber)
	return function()
		local index = table.find(self._Subscribers, subscriber)
		if not index then return end
		table.remove(self._Subscribers, index)
	end
end

function Basket:Watch(selector, onChange)
	local value = selector(self:GetState())
	onChange(value)
	return self:Subscribe(function(state)
		local newValue = selector(state)
		if newValue == value then return end
		value = newValue
		onChange(value)
	end)
end

function Basket.combine(baskets, initialState)
	local state = {}
	for name,basket in pairs(baskets) do
		if basket._Dispatching then
			error("cannot combine baskets from a reducer", 2)
		end
		state[name] = basket:GetState()
	end
	local combinedBasket = Basket.new(Util.Extend(state, initialState or {}))
	for name,basket in pairs(baskets) do
		for actionName,reducer in pairs(basket._Reducers) do
			local fullActionName = name .. "/" .. actionName
			combinedBasket._Reducers[fullActionName] = function(s, payload)
				return Util.Extend(s, {
					[name] = reducer(s[name], payload)
				})
			end
		end
		for actionName in pairs(basket.Actions) do
			local fullActionName = name .. "/" .. actionName
			basket.Actions[actionName] = function(p)
				return {
					Name = fullActionName,
					Payload = p,
				}
			end
		end
	end
	return combinedBasket
end

return Basket
