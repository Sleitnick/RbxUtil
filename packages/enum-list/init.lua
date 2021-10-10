--!strict

-- EnumList
-- Stephen Leitnick
-- January 08, 2021

--[[

	enumList = EnumList.new(name: string, enums: string[])

	enumList:BelongsTo(item): boolean


	Example:

		direction = EnumList.new("Direction", {"Up", "Down", "Left", "Right"})
		leftDir = direction.Left
		print("IsDirection", direction:BelongsTo(leftDir))

--]]


type EnumNames = {string}

local Symbol = require(script.Parent.Symbol)

--[=[
	@class EnumList
	Defines a new Enum.
]=]
local EnumList = {}


--[=[
	@param name string
	@param enums {string}
	@return EnumList
	Constructs a new EnumList.

	```lua
	local directions = EnumList.new("Directions", {
		"Up",
		"Down",
		"Left",
		"Right",
	})

	local direction = directions.Up
	```
]=]
function EnumList.new(name: string, enums: EnumNames)
	local scope = Symbol.new(name, nil)
	local enumItems: {[string]: Symbol.Symbol} = {}
	for _,enumName in ipairs(enums) do
		enumItems[enumName] = Symbol.new(enumName, scope)
	end
	local self = setmetatable({
		_scope = scope;
	}, {
		__index = function(_t, k)
			if enumItems[k] then
				return enumItems[k]
			elseif EnumList[k] then
				return EnumList[k]
			else
				error("Unknown " .. name .. ": " .. tostring(k), 2)
			end
		end;
		__newindex = function()
			error("Cannot add new " .. name, 2)
		end;
	})
	return self
end


--[=[
	@param obj any
	@return boolean
	Returns `true` if `obj` belongs to the EnumList.
]=]
function EnumList:BelongsTo(obj: any): boolean
	return Symbol.IsInScope(obj, self._scope)
end


export type EnumList = typeof(EnumList.new("", {""}))


return EnumList
