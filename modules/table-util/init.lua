--!strict

-- TableUtil
-- Stephen Leitnick
-- September 13, 2017


type Table = {any}
type MapPredicate = (any, any, Table) -> any
type FilterPredicate = (any, any, Table) -> boolean
type ReducePredicate = (number, any, any, Table) -> any
type FindCallback = (any, any, Table) -> boolean
type IteratorFunc = (t: Table, k: any) -> (any, any)

--[=[
	@class TableUtil

	A collection of helpful table utility functions. Many of these functions are carried over from JavaScript or
	Python that are not present in Lua.

	Tables that only work specifically with arrays or dictionaries are marked as such in the documentation.

	:::info Immutability
	All functions (_except_ `SwapRemove`, `SwapRemoveFirstValue`, and `Lock`) treat tables as immutable and will return
	copies of the given table(s) with the operations performed on the copies.
]=]
local TableUtil = {}

local HttpService = game:GetService("HttpService")
local rng = Random.new()


--[=[
	@within TableUtil
	@function Copy
	@param tbl table -- Table to copy
	@param deep boolean? -- Whether or not to perform a deep copy
	@return table

	Creates a copy of the given table. By default, a shallow copy is
	performed. For deep copies, a second boolean argument must be
	passed to the function.

	:::caution No cyclical references
	Deep copies are _not_ protected against cyclical references. Passing
	a table with cyclical references _and_ the `deep` parameter set to
	`true` will result in a stack-overflow.
]=]
local function Copy(t: Table, deep: boolean?): Table
	if deep then
		local function DeepCopy(tbl)
			local tCopy = table.create(#tbl)
			for k,v in pairs(tbl) do
				if type(v) == "table" then
					tCopy[k] = DeepCopy(v)
				else
					tCopy[k] = v
				end
			end
			return tCopy
		end
		return DeepCopy(t)
	else
		if #t > 0 then
			return table.move(t, 1, #t, 1, table.create(#t))
		else
			local tCopy = {}
			for k,v in pairs(t) do
				tCopy[k] = v
			end
			return tCopy
		end
	end
end


--[=[
	@within TableUtil
	@function Sync
	@param srcTbl table -- Source table
	@param templateTbl table -- Template table
	@return table

	Synchronizes the `srcTbl` based on the `templateTbl`. This will make
	sure that `srcTbl` has all of the same keys as `templateTbl`, including
	removing keys in `srcTbl` that are not present in `templateTbl`. This
	is a _deep_ operation, so any nested tables will be synchronized as
	well.

	```lua
	local template = {kills = 0, deaths = 0, xp = 0}
	local data = {kills = 10, experience = 12}
	data = TableUtil.Sync(data, template)
	print(data) --> {kills = 10, deaths = 0, xp = 0}
	```

	:::caution Data Loss Warning
	This is a two-way sync, so the source table will have data
	_removed_ that isn't found in the template table. This can
	be problematic if used for player data, where there might
	be dynamic data added that isn't in the template.

	For player data, use `TableUtil.Reconcile` instead.
]=]
local function Sync(srcTbl: Table, templateTbl: Table): Table

	assert(type(srcTbl) == "table", "First argument must be a table")
	assert(type(templateTbl) == "table", "Second argument must be a table")

	local tbl = Copy(srcTbl)

	-- If 'tbl' has something 'templateTbl' doesn't, then remove it from 'tbl'
	-- If 'tbl' has something of a different type than 'templateTbl', copy from 'templateTbl'
	-- If 'templateTbl' has something 'tbl' doesn't, then add it to 'tbl'
	for k,v in pairs(tbl) do

		local vTemplate = templateTbl[k]

		-- Remove keys not within template:
		if vTemplate == nil then
			tbl[k] = nil

		-- Synchronize data types:
		elseif type(v) ~= type(vTemplate) then
			if type(vTemplate) == "table" then
				tbl[k] = Copy(vTemplate, true)
			else
				tbl[k] = vTemplate
			end

		-- Synchronize sub-tables:
		elseif type(v) == "table" then
			tbl[k] = Sync(v, vTemplate)
		end

	end

	-- Add any missing keys:
	for k,vTemplate in pairs(templateTbl) do

		local v = tbl[k]

		if v == nil then
			if type(vTemplate) == "table" then
				tbl[k] = Copy(vTemplate, true)
			else
				tbl[k] = vTemplate
			end
		end

	end

	return tbl

end


--[=[
	@within TableUtil
	@function Reconcile
	@param source table
	@param template table
	@return table

	Performs a one-way sync on the `source` table against the
	`template` table. Any keys found in `template` that are
	not found in `source` will be added to `source`. This is
	useful for syncing player data against data template tables
	to ensure players have all the necessary keys, while
	maintaining existing keys that may no longer be in the
	template.

	This is a deep operation, so nested tables will also be
	properly reconciled.

	```lua
	local template = {kills = 0, deaths = 0, xp = 0}
	local data = {kills = 10, abc = 20}
	local correctedData = TableUtil.Reconcile(data, template)
	
	print(correctedData) --> {kills = 10, deaths = 0, xp = 0, abc = 30}
	```
]=]
local function Reconcile(src: Table, template: Table): Table

	assert(type(src) == "table", "First argument must be a table")
	assert(type(template) == "table", "Second argument must be a table")

	local tbl = Copy(src)

	for k,v in pairs(template) do
		local sv = src[k]
		if sv == nil then
			if type(v) == "table" then
				tbl[k] = Copy(v, true)
			else
				tbl[k] = v
			end
		elseif type(sv) == "table" then
			if type(v) == "table" then
				tbl[k] = Reconcile(sv, v)
			else
				tbl[k] = Copy(sv, true)
			end
		end
	end

	return tbl

end


--[=[
	@within TableUtil
	@function SwapRemove
	@param tbl table -- Array
	@param i number -- Index

	Removes index `i` in the table by swapping the value at `i` with
	the last value in the array, and then trimming off the last
	value from the array.

	This allows removal of the value at `i` in `O(1)` time, but does
	not preserve array ordering. If a value needs to be removed from
	an array, but ordering of the array does not matter, using
	`SwapRemove` is always preferred over `table.remove`.

	In the following example, we remove "B" at index 2. SwapRemove does
	this by moving the last value "E" over top of "B", and then trimming
	off "E" at the end of the array:
	```lua
	local t = {"A", "B", "C", "D", "E"}
	TableUtil.SwapRemove(t, 2) -- Remove "B"
	print(t) --> {"A", "E", "C", "D"}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function SwapRemove(t: Table, i: number)
	local n = #t
	t[i] = t[n]
	t[n] = nil
end


--[=[
	@within TableUtil
	@function SwapRemoveFirstValue
	@param tbl table -- Array
	@param v any -- Value to find
	@return number?

	Performs `table.find(tbl, v)` to find the index of the given
	value, and then performs `TableUtil.SwapRemove` on that index.

	```lua
	local t = {"A", "B", "C", "D", "E"}
	TableUtil.SwapRemoveFirstValue(t, "C")
	print(t) --> {"A", "B", "E", "D"}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function SwapRemoveFirstValue(t: Table, v: any): number?
	local index: number? = table.find(t, v)
	if index then
		SwapRemove(t, index)
	end
	return index
end


--[=[
	@within TableUtil
	@function Map
	@param tbl table
	@param predicate (value: any, key: any, tbl: table) -> newValue: any
	@return table

	Performs a map operation against the given table, which can be used to
	map new values based on the old values at given keys/indices.

	For example:

	```lua
	local t = {A = 10, B = 20, C = 30}
	local t2 = TableUtil.Map(t, function(key, value)
		return value * 2
	end)
	print(t2) --> {A = 20, B = 40, C = 60}
	```
]=]
local function Map(t: Table, f: MapPredicate): Table
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	for k,v in pairs(t) do
		newT[k] = f(v, k, t)
	end
	return newT
end


--[=[
	@within TableUtil
	@function Filter
	@param tbl table
	@param predicate (value: any, key: any, tbl: table) -> keep: boolean
	@return table

	Performs a filter operation against the given table, which can be used to
	filter out unwanted values from the table.

	For example:

	```lua
	local t = {A = 10, B = 20, C = 30}
	local t2 = TableUtil.Filter(t, function(key, value)
		return value > 15
	end)
	print(t2) --> {B = 40, C = 60}
	```
]=]
local function Filter(t: Table, f: FilterPredicate): Table
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	if #t > 0 then
		local n = 0
		for i,v in ipairs(t) do
			if f(v, i, t) then
				n += 1
				newT[n] = v
			end
		end
	else
		for k,v in pairs(t) do
			if f(v, k, t) then
				newT[k] = v
			end
		end
	end
	return newT
end


--[=[
	@within TableUtil
	@function Reduce
	@param tbl table
	@param predicate (accumulator: any, value: any, index: any, tbl: table) -> result: any
	@return table

	Performs a reduce operation against the given table, which can be used to
	reduce the table into a single value. This could be used to sum up a table
	or transform all the values into a compound value of any kind.

	For example:

	```lua
	local t = {10, 20, 30, 40}
	local result = TableUtil.Reduce(t, function(accum, value)
		return accum + value
	end)
	print(result) --> 100
	```
]=]
local function Reduce(t: Table, f: ReducePredicate, init: any?): any
	assert(type(t) == "table", "First argument must be a table")
	assert(type(f) == "function", "Second argument must be a function")
	local result = init
	if #t > 0 then
		local start = 1
		if init == nil then
			result = t[1]
			start = 2
		end
		for i = start,#t do
			result = f(result, t[i], i, t)
		end
	else
		local start = nil
		if init == nil then
			result = next(t)
			start = result
		end
		for k,v in next,t,start do
			result = f(result, v, k, t)
		end
	end
	return result
end


--[=[
	@within TableUtil
	@function Assign
	@param target table
	@param ... table
	@return table

	Copies all values of the given tables into the `target` table.

	```lua
	local t = {A = 10}
	local t2 = {B = 20}
	local t3 = {C = 30, D = 40}
	local newT = TableUtil.Assign(t, t2, t3)
	print(newT) --> {A = 10, B = 20, C = 30, D = 40}
	```
]=]
local function Assign(target: Table, ...: Table): Table
	local tbl = Copy(target)
	for _,src in ipairs({...}) do
		for k,v in pairs(src) do
			tbl[k] = v
		end
	end
	return tbl
end


--[=[
	@within TableUtil
	@function Extend
	@param target table
	@param extension table
	@return table

	Extends the target array with the extension array.

	```lua
	local t = {10, 20, 30}
	local t2 = {30, 40, 50}
	local tNew = TableUtil.Extend(t, t2)
	print(tNew) --> {10, 20, 30, 30, 40, 50}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function Extend(target: Table, extension: Table): Table
	local tbl = Copy(target)
	for _,v in ipairs(extension) do
		table.insert(tbl, v)
	end
	return tbl
end


--[=[
	@within TableUtil
	@function Reverse
	@param tbl table
	@return table

	Reverses the array.

	```lua
	local t = {1, 5, 10}
	local tReverse = TableUtil.Reverse(t)
	print(tReverse) --> {10, 5, 1}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function Reverse(tbl: Table): Table
	local n = #tbl
	local tblRev = table.create(n)
	for i = 1,n do
		tblRev[i] = tbl[n - i + 1]
	end
	return tblRev
end


--[=[
	@within TableUtil
	@function Shuffle
	@param tbl table
	@param rngOverride Random?
	@return table

	Shuffles the table.

	```lua
	local t = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	local shuffled = TableUtil.Shuffle(t)
	print(shuffled) --> e.g. {9, 4, 6, 7, 3, 1, 5, 8, 2}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function Shuffle(tbl: Table, rngOverride: Random?): Table
	assert(type(tbl) == "table", "First argument must be a table")
	local shuffled = Copy(tbl)
	local random = if typeof(rngOverride) == "Random" then rngOverride else rng
	for i = #tbl, 2, -1 do
		local j = random:NextInteger(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end


--[=[
	@within TableUtil
	@function Sample
	@param tbl table
	@param sampleSize number
	@param rngOverride Random?
	@return table

	Returns a random sample of the table.

	```lua
	local t = {1, 2, 3, 4, 5, 6, 7, 8, 9}
	local sample = TableUtil.Sample(t, 3)
	print(sample) --> e.g. {6, 2, 5}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function Sample(tbl: Table, size: number, rngOverride: Random?): Table
	assert(type(tbl) == "table", "First argument must be a table")
	assert(type(size) == "number", "Second argument must be a number")
	local shuffled = Copy(tbl)
	local sample = table.create(size)
	local random = if typeof(rngOverride) == "Random" then rngOverride else rng
	local len = #tbl
	size = math.clamp(size, 1, len)
	for i = 1,size do
		local j = random:NextInteger(i, len)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	table.move(shuffled, 1, size, 1, sample)
	return sample
end


--[=[
	@within TableUtil
	@function Flat
	@param tbl table
	@param depth number?
	@return table

	Returns a new table where all sub-arrays have been
	bubbled up to the top. The depth at which the scan
	is performed is dictated by the `depth` parameter,
	which is set to `1` by default.

	```lua
	local t = {{10, 20}, {90, 100}, {30, 15}}
	local flat = TableUtil.Flat(t)
	print(flat) --> {10, 20, 90, 100, 30, 15}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function Flat(tbl: Table, depth: number?): Table
	local maxDepth: number = if type(depth) == "number" then depth else 1
	local flatTbl = table.create(#tbl)
	local function Scan(t: Table, d: number)
		for _,v in ipairs(t) do
			if type(v) == "table" and d < maxDepth then
				Scan(v, d + 1)
			else
				table.insert(flatTbl, v)
			end
		end
	end
	Scan(tbl, 0)
	return flatTbl
end


--[=[
	@within TableUtil
	@function FlatMap
	@param tbl table
	@param predicate (key: any, value: any, tbl: table) -> newValue: any
	@return table

	Calls `TableUtil.Map` on the given table and predicate, and then
	calls `TableUtil.Flat` on the result from the map operation.

	```lua
	local t = {10, 20, 30}
	local result = TableUtil.FlatMap(t, function(value)
		return {value, value * 2}
	end)
	print(result) --> {10, 20, 20, 40, 30, 60}
	```

	:::note Arrays only
	This function works on arrays, but not dictionaries.
]=]
local function FlatMap(tbl: Table, callback: MapPredicate): Table
	return Flat(Map(tbl, callback))
end


--[=[
	@within TableUtil
	@function Keys
	@param tbl table
	@return table

	Returns an array with all the keys in the table.

	```lua
	local t = {A = 10, B = 20, C = 30}
	local keys = TableUtil.Keys(t)
	print(keys) --> {"A", "B", "C"}
	```

	:::caution Ordering
	The ordering of the keys is never guaranteed. If order is imperative, call
	`table.sort` on the resulting `keys` array.
	```lua
	local keys = TableUtil.Keys(t)
	table.sort(keys)
	```
]=]
local function Keys(tbl: Table): Table
	local keys = table.create(#tbl)
	for k in pairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end


--[=[
	@within TableUtil
	@function Find
	@param tbl table
	@param callback (value: any, index: any, tbl: table) -> boolean
	@return (value: any?, key: any?)

	Performs a linear scan across the table and calls `callback` on
	each item in the array. Returns the value and key of the first
	pair in which the callback returns `true`.

	```lua
	local t = {
		{Name = "Bob", Age = 20};
		{Name = "Jill", Age = 30};
		{Name = "Ann", Age = 25};
	}

	-- Find first person who has a name starting with J:
	local firstPersonWithJ = TableUtil.Find(t, function(person)
		return person.Name:sub(1, 1):lower() == "j"
	end)

	print(firstPersonWithJ) --> {Name = "Jill", Age = 30}
	```

	:::caution Dictionary Ordering
	While `Find` can also be used with dictionaries, dictionary ordering is never
	guaranteed, and thus the result could be different if there are more
	than one possible matches given the data and callback function.
]=]
local function Find(tbl: Table, callback: FindCallback): (any?, any?)
	for k,v in pairs(tbl) do
		if callback(v, k, tbl) then
			return v, k
		end
	end
	return nil, nil
end


--[=[
	@within TableUtil
	@function Every
	@param tbl table
	@param callback (value: any, index: any, tbl: table) -> boolean
	@return boolean

	Returns `true` if the `callback` also returns `true` for _every_
	item in the table.

	```lua
	local t = {10, 20, 40, 50, 60}

	local allAboveZero = TableUtil.Every(t, function(value)
		return value > 0
	end)

	print("All above zero:", allAboveZero) --> All above zero: true
	```
]=]
local function Every(tbl: Table, callback: FindCallback): boolean
	for k,v in pairs(tbl) do
		if not callback(v, k, tbl) then
			return false
		end
	end
	return true
end


--[=[
	@within TableUtil
	@function Some
	@param tbl table
	@param callback (value: any, index: any, tbl: table) -> boolean
	@return boolean

	Returns `true` if the `callback` also returns `true` for _at least
	one_ of the items in the table.

	```lua
	local t = {10, 20, 40, 50, 60}

	local someBelowTwenty = TableUtil.Some(t, function(value)
		return value < 20
	end)

	print("Some below twenty:", someBelowTwenty) --> Some below twenty: true
	```
]=]
local function Some(tbl: Table, callback: FindCallback): boolean
	for k,v in pairs(tbl) do
		if callback(v, k, tbl) then
			return true
		end
	end
	return false
end


--[=[
	@within TableUtil
	@function Truncate
	@param tbl table
	@param length number
	@return table

	Returns a new table truncated to the length of `length`.

	```lua
	local t = {10, 20, 30, 40, 50, 60, 70, 80}
	local tTruncated = TableUtil.Truncate(t, 3)
	print(tTruncated) --> {10, 20, 30}
	```
]=]
local function Truncate(tbl: Table, len: number): Table
	return table.move(tbl, 1, len, 1, table.create(len))
end


--[=[
	@within TableUtil
	@function Zip
	@param ... table
	@return (iter: (t: table, k: any) -> (key: any?, values: table?), tbl: table, startIndex: any?)

	Returns an iterator that can scan through multiple tables at the same time side-by-side, matching
	against shared keys/indices.

	```lua
	local t1 = {10, 20, 30, 40, 50}
	local t2 = {60, 70, 80, 90, 100}

	for key,values in TableUtil.Zip(t1, t2) do
		print(key, values)
	end

	--[[
		Outputs:
		1 {10, 60}
		2 {20, 70}
		3 {30, 80}
		4 {40, 90}
		5 {50, 100}
	--]]
	```
]=]
local function Zip(...): (IteratorFunc, Table, any)
	assert(select("#", ...) > 0, "Must supply at least 1 table")
	local function ZipIteratorArray(all: Table, k: number)
		k += 1
		local values = {}
		for i,t in ipairs(all) do
			local v = t[k]
			if v ~= nil then
				values[i] = v
			else
				return nil, nil
			end
		end
		return k, values
	end
	local function ZipIteratorMap(all: Table, k: any)
		local values = {}
		for i,t in ipairs(all) do
			local v = next(t, k)
			if v ~= nil then
				values[i] = v
			else
				return nil, nil
			end
		end
		return k, values
	end
	local all = {...}
	if #all[1] > 0 then
		return ZipIteratorArray, all, 0
	else
		return ZipIteratorMap, all, nil
	end
end


--[=[
	@within TableUtil
	@function Lock
	@param tbl table
	@return table

	Locks the table using `table.freeze`, as well as any
	nested tables within the given table. This will lock
	the whole deep structure of the table, disallowing any
	further modifications.

	```lua
	local tbl = {xyz = {abc = 32}}
	tbl.xyz.abc = 28 -- Works fine
	TableUtil.Lock(tbl)
	tbl.xyz.abc = 64 -- Will throw an error (cannot modify readonly table)
	```
]=]
local function Lock(tbl: Table): Table
	local function Freeze(t: Table)
		for k,v in pairs(t) do
			if type(v) == "table" then
				t[k] = Freeze(v)
			end
		end
		return table.freeze(t)
	end
	return Freeze(tbl)
end


--[=[
	@within TableUtil
	@function IsEmpty
	@param tbl table
	@return boolean

	Returns `true` if the given table is empty. This is
	simply performed by checking if `next(tbl)` is `nil`
	and works for both arrays and dictionaries. This is
	useful when needing to check if a table is empty but
	not knowing if it is an array or dictionary.

	```lua
	TableUtil.IsEmpty({}) -- true
	TableUtil.IsEmpty({"abc"}) -- false
	TableUtil.IsEmpty({abc = 32}) -- false
	```
]=]
local function IsEmpty(tbl)
	return next(tbl) == nil
end


--[=[
	@within TableUtil
	@function EncodeJSON
	@param value any
	@return string

	Proxy for [`HttpService:JSONEncode`](https://developer.roblox.com/en-us/api-reference/function/HttpService/JSONEncode).
]=]
local function EncodeJSON(value: any): string
	return HttpService:JSONEncode(value)
end


--[=[
	@within TableUtil
	@function DecodeJSON
	@param value any
	@return string

	Proxy for [`HttpService:JSONDecode`](https://developer.roblox.com/en-us/api-reference/function/HttpService/JSONDecode).
]=]
local function DecodeJSON(str: string): any
	return HttpService:JSONDecode(str)
end


TableUtil.Copy = Copy
TableUtil.Sync = Sync
TableUtil.Reconcile = Reconcile
TableUtil.SwapRemove = SwapRemove
TableUtil.SwapRemoveFirstValue = SwapRemoveFirstValue
TableUtil.Map = Map
TableUtil.Filter = Filter
TableUtil.Reduce = Reduce
TableUtil.Assign = Assign
TableUtil.Extend = Extend
TableUtil.Reverse = Reverse
TableUtil.Shuffle = Shuffle
TableUtil.Sample = Sample
TableUtil.Flat = Flat
TableUtil.FlatMap = FlatMap
TableUtil.Keys = Keys
TableUtil.Find = Find
TableUtil.Every = Every
TableUtil.Some = Some
TableUtil.Truncate = Truncate
TableUtil.Zip = Zip
TableUtil.Lock = Lock
TableUtil.IsEmpty = IsEmpty
TableUtil.EncodeJSON = EncodeJSON
TableUtil.DecodeJSON = DecodeJSON

return TableUtil
