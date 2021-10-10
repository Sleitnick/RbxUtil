--!strict

-- Loader
-- Stephen Leitnick
-- January 10, 2021

--[[

	Loads all ModuleScripts within the given parent.

	Loader.LoadChildren(parent: Instance): module[]
	Loader.LoadDescendants(parent: Instance): module[]

--]]

--[=[
	@class Loader

	The Loader module will require all children or descendant ModuleScripts.
]=]
local Loader = {}

type Module = {}
type Modules = {Module}


--[=[
	Requires all children ModuleScripts

	@param parent Instance -- Parent to scan
	@return {ModuleScript} -- Array of required modules
]=]
function Loader.LoadChildren(parent: Instance): Modules
	local modules: Modules = {}
	for _,child in ipairs(parent:GetChildren()) do
		if child:IsA("ModuleScript") then
			local m = require(child)
			table.insert(modules, m)
		end
	end
	return modules
end


--[=[
	Requires all descendant ModuleScripts

	@param parent Instance -- Parent to scan
	@return {ModuleScript} -- Array of required modules
]=]
function Loader.LoadDescendants(parent: Instance): Modules
	local modules: Modules = {}
	for _,descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("ModuleScript") then
			local m = require(descendant)
			table.insert(modules, m)
		end
	end
	return modules
end


return Loader
