--!strict

-- Loader
-- Stephen Leitnick
-- January 10, 2021

--[[

	Loads all ModuleScripts within the given parent.

	Loader.LoadChildren(parent: Instance, returnDictionary: boolean?): module[]
	Loader.LoadDescendants(parent: Instance, returnDictionary: boolean?): module[]
	Loader.LoadInFolders(parent: Instance, returnDictionary: boolean?): module[]

--]]

--[=[
	@class Loader

	The Loader module will require all children or descendant ModuleScripts.
]=]
local Loader = {}

type Module = {}
type ModuleName = string
type DictionaryOfModules = { ModuleName: Module }
type ArrayOfModules = { Module }

local function loadModulesIn(
	parent: Instance,
	deep: boolean?,
	returnDictionary: boolean?
): ArrayOfModules | DictionaryOfModules
	local instances = if deep then parent:GetDescendants() else parent:GetChildren()
	local modules: ArrayOfModules | DictionaryOfModules = {}
	for _, instance in ipairs(instances) do
		if instance:IsA("ModuleScript") then
			local m: Module = require(instance)

			if returnDictionary then
				modules[instance.Name] = m
			else
				table.insert(modules, m)
			end
		end
	end
	return modules
end


--[=[
	Only requires ModuleScripts that are parented to folders. Especially useful
	when you have ModuleScripts parented to ModuleScripts that shouldn't be
	required from an external source other than the parent ModuleScript.

	```lua
	-- Can return arrays:
	local systems = Loader.LoadInFolders(script.Systems)

	scheduleSystems(systems)

	-- Can also return dictionaries:
	local humanoidStateCalculationModules = Loader.LoadInFolders(script.HumanoidStateModules, true)

	for stateName, module in pairs(humanoidStateCalculationModules) do
		debug.profilebegin(string.format("Calculate Is%s", stateName))
		module.Calculate()
		debug.profileend()
	end
	```

	@param parent Instance -- Parent to scan
	@param returnDictionary boolean -- If the modules returned should be a dictionary
	@return ArrayOfModules | DictionaryOfModules -- Array or dictionary of required modules
]=]
function Loader.LoadInFolders(parent: Instance, returnDictionary: boolean?): ArrayOfModules | DictionaryOfModules
	local modules: ArrayOfModules | DictionaryOfModules = {}
	local function loadDeep(instance: Instance)
		local childModules = loadModulesIn(instance, false, returnDictionary)
		for key: ModuleName | number, module in pairs(childModules) do
			if returnDictionary then
				modules[key] = module
			else
				table.insert(modules, module)
			end
		end
		for _, child in ipairs(instance:GetChildren()) do
			if child:IsA("Folder") then
				loadDeep(child)
			end
		end
	end
	loadDeep(parent)
	return modules
end


--[=[
	Requires all children ModuleScripts

	@param parent Instance -- Parent to scan
	@param returnDictionary boolean -- If the modules returned should be a dictionary
	@return ArrayOfModules | DictionaryOfModules -- Array or dictionary of required modules
]=]
function Loader.LoadChildren(parent: Instance, returnDictionary: boolean?): ArrayOfModules | DictionaryOfModules
	return loadModulesIn(parent, false, returnDictionary)
end


--[=[
	Requires all descendant ModuleScripts

	@param parent Instance -- Parent to scan
	@param returnDictionary boolean -- If the modules returned should be a dictionary
	@return ArrayOfModules | DictionaryOfModules -- Array or dictionary of required modules
]=]
function Loader.LoadDescendants(parent: Instance, returnDictionary: boolean?): ArrayOfModules | DictionaryOfModules
	return loadModulesIn(parent, true, returnDictionary)
end


return Loader
