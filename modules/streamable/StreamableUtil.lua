--!strict

-- StreamableUtil
-- Stephen Leitnick
-- March 03, 2021


local Trove = require(script.Parent.Parent.Trove)
local _Streamable = require(script.Parent.Streamable)

type Streamables = {_Streamable.Streamable}
type CompoundHandler = (Streamables) -> () -> ()

--[=[
	@within StreamableUtil
	@type CompoundHandler ({Streamable}) -> () -> ()
	A function that handles compound streamables. It should return a function that acts
	as a cleanup function.
]=]

--[=[
	@class StreamableUtil
	@client
	A utility library for the Streamable class.

	```lua
	local StreamableUtil = require(packages.Streamable).StreamableUtil
	```
]=]
local StreamableUtil = {}

--[=[
	@param streamables {Streamable}
	Creates a compound streamable around all the given streamables. The compound
	streamable's observer handler will be fired once _all_ the given streamables
	are in existence, and will be cleaned up when _any_ of the streamables
	disappear.

	```lua
	local s1 = Streamable.new(workspace, "Part1")
	local s2 = Streamable.new(workspace, "Part2")

	local compoundTrove = StreamableUtil.Compound({S1 = s1, S2 = s2}, function(streamables, trove)
		local part1 = streamables.S1.Instance
		local part2 = streamables.S2.Instance
		trove:Add(function()
			print("Cleanup")
		end)
	end)
	```
]=]
function StreamableUtil.Compound(streamables: Streamables, handler: CompoundHandler): () -> ()
	local compoundTrove = Trove.new()
	local observeAllTrove = Trove.new()
	local allAvailable = false
	local function Check()
		if allAvailable then return end
		for _,streamable in pairs(streamables) do
			if not streamable.Instance then
				return
			end
		end
		allAvailable = true
		local cleanup = handler(streamables)
		if type(cleanup) == "function" then
			observeAllTrove:Add(cleanup)
		end
	end
	local function Cleanup()
		if not allAvailable then return end
		allAvailable = false
		observeAllTrove:Clean()
	end
	for _,streamable in pairs(streamables) do
		compoundTrove:Add(streamable:Observe(function(_child)
			Check()
			return Cleanup
		end))
	end
	compoundTrove:Add(Cleanup)
	return function()
		compoundTrove:Destroy()
	end
end

return StreamableUtil
