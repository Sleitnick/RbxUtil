--!strict

--[=[
	@class Query

	Adds helpful functions that wrap
	[`Instance:QueryDescendants()`](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants).
]=]

local Query = {}

--[=[
	@within Query

	Equivalent to [`parent:QueryDescendants(selector)`](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants).
]=]
function Query.all(parent: Instance, selector: string): { Instance }
	return parent:QueryDescendants(selector)
end

--[=[
	@within Query

	Returns the query result, filtered by the `filter` function. Ideally, most of
	the filtering should be done with the selector itself. However, if the selector
	is not enough, this function can be used to further filter the results.

	```lua
	local buttons = Query.filter(workspace, ".Button", function(instance)
		return instance.Transparency > 0.25
	end)
	```
]=]
function Query.filter(parent: Instance, selector: string, filter: (Instance) -> boolean): { Instance }
	local instances = parent:QueryDescendants(selector)
	for i = #instances, 1, -1 do
		if not filter(instances[i]) then
			table.remove(instances, i)
		end
	end
	return instances
end

--[=[
	@within Query

	Returns the query result mapped by the `map` function.

	```lua
	local Button = {}

	function Button.new(btn: BasePart)
		...
	end

	----

	local buttons = Query.map(workspace, ".Button", function(instance)
		return Button.new(instance)
	end)
	```
]=]
function Query.map<T>(parent: Instance, selector: string, map: (Instance) -> T): { T }
	local instances = parent:QueryDescendants(selector)
	local mapped = table.create(#instances)
	for i, instance in instances do
		mapped[i] = map(instance)
	end
	return mapped
end

--[=[
	@within Query

	Returns the first item from the query. Might be `nil` if the query returns
	nothing.

	This is equivalent to `parent:QueryDescendants(selector)[1]`.

	```lua
	-- Find an instance tagged with 'Tycoon' that has
	-- the OwnerId attribute matching the player's UserId:
	local tycoon = Query.first(workspace, `.Tycoon[$OwnerId = {player.UserId}]`)

	if tycoon then
		...
	end
	```
]=]
function Query.first(parent: Instance, selector: string): Instance?
	return parent:QueryDescendants(selector)[1]
end

--[=[
	@within Query

	Asserts that the query returns exactly one instance. The instance is returned.
	This is useful when attempting to find an exact match of an instance that
	must exist.

	If the result returns zero or more than one result, an error is thrown.

	```lua
	-- Find a SpawnLocation that has the MainSpawn attribute set to true:
	local spawnPoint = Query.one(workspace, "SpawnLocation[$MainSpawn = true]")
	```
]=]
function Query.one(parent: Instance, selector: string): Instance
	local instances = parent:QueryDescendants(selector)
	if #instances ~= 1 then
		error(`expected 1 instance from query; got {#instances} instances (selector: {selector})`, 2)
	end

	return instances[1]
end

return Query
