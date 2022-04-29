-- TableWatcher
-- Stephen Leitnick
-- April 29, 2022


local Util = require(script.Parent.Util)

local watchers = {}
setmetatable(watchers, {__mode = "k"})

local WatcherMt = {}

function WatcherMt:__index(index)
	local w = watchers[self]
	local c = w.Changes[index]
	if c ~= nil then
		if c == Util.None then
			return nil
		else
			return c
		end
	end
	return w.Tbl[index]
end

function WatcherMt:__newindex(index, value)
	local w = watchers[self]
	if w.Tbl[index] == value then return end
	if value == nil then
		w.Changes[index] = Util.None
	else
		w.Changes[index] = value
	end
end

function WatcherMt:__call()
	local w = watchers[self]
	if next(w.Changes) == nil then
		return w.Tbl
	end
	return Util.Extend(w.Tbl, w.Changes)
end

local function TableWatcher(t)
	local watcher = {}
	watchers[watcher] = {
		Changes = {},
		Tbl = t,
	}
	setmetatable(watcher, WatcherMt)
	return watcher
end

return TableWatcher
