--!strict

-- Symbol
-- Stephen Leitnick
-- December 27, 2020

--[[

	symbol = Symbol.new(id: string [, scope: Symbol])

	Symbol.Is(obj: any): boolean
	Symbol.IsInScope(obj: any, scope: Symbol): boolean

--]]


local CLASSNAME = "Symbol"


--[=[
	@class Symbol

	Symbols are simply unique objects that can be used as unique identifiers.
]=]
local Symbol = {}
Symbol.__index = Symbol

--[=[
	Constructs a new symbol

	@param id any -- Identifier for the symbol (usually a string)
	@param scope Symbol? -- Optional symbol scope
	@return boolean -- Returns `true` if the `obj` parameter is a Symbol
]=]
function Symbol.new(id: any, scope: any)
	assert(id ~= nil, "Symbol ID cannot be nil")
	if scope ~= nil then
		assert(Symbol.Is(scope), "Scope must be a Symbol or nil")
	end
	local self = setmetatable({
		ClassName = CLASSNAME;
		_id = id;
		_scope = scope;
	}, Symbol)
	return self
end


--[=[
	Checks if the given object is a Symbol.

	@param obj any -- Anything
	@return boolean -- Returns `true` if the `obj` parameter is a Symbol
]=]
function Symbol.Is(obj: any): boolean
	return type(obj) == "table" and getmetatable(obj) == Symbol
end



--[=[
	Checks if the given object is a Symbol an in the given scope

	@param obj any -- Anything
	@param scope Symbol -- Scope symbol
	@return boolean -- Returns `true` if the `obj` parameter is a Symbol and in the given scope
]=]
function Symbol.IsInScope(obj: any, scope: Symbol): boolean
	return Symbol.Is(obj) and obj._scope == scope
end


function Symbol:__tostring()
	return ("Symbol<%s>"):format(self._id)
end


export type Symbol = typeof(Symbol.new("Test", nil))


return Symbol
