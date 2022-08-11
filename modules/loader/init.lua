--[=[
	@class Loader

	The Loader module will require all children or descendant ModuleScripts. There are also
	some utility functions included, which assist with loading and starting modules in
	single-script environments.

	For example, here is a loader that loads all ModuleScripts under a folder that end with
	the name Service, and then calls all of their OnStart methods:
	```lua
	local MyModules = ReplicatedStorage.MyModules
	Loader.SpawnAll(
		Loader.LoadDescendants(MyModules, Loader.MatchesName("Service$")),
		"OnStart"
	)
	```
]=]
local Loader = {}

--[=[
	@within Loader
	@type PredicateFn (module: ModuleScript) -> boolean
	Predicate function type.
]=]
type PredicateFn = (module: ModuleScript) -> boolean

--[=[
	Requires all children ModuleScripts.

	If a `predicate` function is provided, then the module will only
	be loaded if the predicate returns `true` for the the given
	ModuleScript.

	```lua
	-- Load all ModuleScripts directly under MyModules:
	Loader.LoadChildren(ReplicatedStorage.MyModules)

	-- Load all ModuleScripts directly under MyModules if they have names ending in 'Service':
	Loader.LoadChildren(ReplicatedStorage.MyModules, function(moduleScript)
		return moduleScript.Name:match("Service$") ~= nil
	end)
	```
]=]
function Loader.LoadChildren(parent: Instance, predicate: PredicateFn?): { [string]: any }
	local modules: { [string]: any } = {}
	for _, child in parent:GetChildren() do
		if child:IsA("ModuleScript") then
			if predicate and not predicate(child) then
				continue
			end
			local m = require(child)
			modules[child.Name] = m
		end
	end
	return modules
end

--[=[
	Requires all descendant ModuleScripts.

	If a `predicate` function is provided, then the module will only
	be loaded if the predicate returns `true` for the the given
	ModuleScript.

	```lua
	-- Load all ModuleScripts under MyModules:
	Loader.LoadDescendants(ReplicatedStorage.MyModules)

	-- Load all ModuleScripts under MyModules if they have names ending in 'Service':
	Loader.LoadDescendants(ReplicatedStorage.MyModules, function(moduleScript)
		return moduleScript.Name:match("Service$") ~= nil
	end)
]=]
function Loader.LoadDescendants(parent: Instance, predicate: PredicateFn?): { [string]: any }
	local modules: { [string]: any } = {}
	for _, descendant in parent:GetDescendants() do
		if descendant:IsA("ModuleScript") then
			if predicate and not predicate(descendant) then
				continue
			end
			local m = require(descendant)
			modules[descendant.Name] = m
		end
	end
	return modules
end

--[=[
	A commonly-used predicate in the `LoadChildren` and `LoadDescendants`
	functions is one to match names. Therefore, the `MatchesName` utility
	function provides a quick way to create such predicates.

	```lua
	Loader.LoadDescendants(ReplicatedStorage.MyModules, Loader.MatchesName("Service$"))
	```
]=]
function Loader.MatchesName(matchName: string): (module: ModuleScript) -> boolean
	return function(moduleScript: ModuleScript): boolean
		return moduleScript.Name:match(matchName) ~= nil
	end
end

--[=[
	Utility function for spawning a specific method in all given modules.
	If a module does not contain the specified method, it is simply
	skipped. Methods are called with `task.spawn` internally.

	For example, if the modules are expected to have an `OnStart()` method,
	then `SpawnAll()` could be used to start all of them directly after
	they have been loaded:

	```lua
	local MyModules = ReplicatedStorage.MyModules

	-- Load all modules under MyModules and then call their OnStart methods:
	Loader.SpawnAll(Loader.LoadDescendants(MyModules), "OnStart")

	-- Same as above, but only loads modules with names that end with Service:
	Loader.SpawnAll(
		Loader.LoadDescendants(MyModules, Loader.MatchesName("Service$")),
		"OnStart"
	)
	```
]=]
function Loader.SpawnAll(loadedModules: { [string]: any }, methodName: string)
	for name, mod in loadedModules do
		local method = mod[methodName]
		if type(method) == "function" then
			task.spawn(function()
				debug.setmemorycategory(name)
				method(mod)
			end)
		end
	end
end

return Loader
