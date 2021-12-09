-- Shake
-- Stephen Leitnick
-- December 09, 2021


local Shake = {}
Shake.__index = Shake


function Shake.new()
	local self = setmetatable({}, Shake)
	return self
end


function Shake:Destroy()
end


return Shake
