--!strict

-- Util
-- Stephen Leitnick
-- April 29, 2022


type AnyTable = {[any]: any}

local Util = {}

Util.None = newproxy()

function Util.DeepFreeze(tbl: AnyTable): AnyTable
	table.freeze(tbl)
	for _,v in pairs(tbl) do
		if type(v) == "table" then
			Util.DeepFreeze(v)
		end
	end
	return tbl
end

function Util.DeepCopy(tbl: AnyTable): AnyTable
	local newTbl = table.clone(tbl)
	for k,v in pairs(newTbl) do
		if type(v) == "table" then
			newTbl[k] = Util.DeepCopy(v)
		end
	end
	return newTbl
end

function Util.Extend(original: AnyTable, extension: AnyTable): AnyTable
	local t = Util.DeepCopy(original)
	for k,v in pairs(extension) do
		if type(v) == "table" then
			if type(original[k]) == "table" then
				t[k] = Util.Extend(original[k], v)
			else
				t[k] = Util.DeepCopy(v)
			end
		elseif v == Util.None then
			t[k] = nil
		else
			t[k] = v
		end
	end
	return t
end

return Util
