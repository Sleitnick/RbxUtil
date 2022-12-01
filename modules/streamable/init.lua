-- Streamable
-- Rocky28447
-- November 30th, 2022

--!strict

local StreamableApi: any = require(script.Streamable)
local StreamableUtilApi: any = require(script.StreamableUtil)

local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)

type Connection = Signal.Connection
type Signal = Signal.Class
type Trove = Trove.Class

export type Streamable = {
	Observe: (self: Streamable, handler: (instance: Instance, trove: Trove) -> ()) -> Connection,
	Destroy: (self: Streamable) -> (),
}

return {
	Streamable = StreamableApi,
	StreamableUtil = StreamableUtilApi,
} :: {
	Streamable: {
		new: (parent: Instance, childName: string) -> Streamable,
		primary: (parent: Model) -> Streamable,
	},

	StreamableUtil: {
		Compound: (streamables: { Streamable }, handler: ({ [string]: Instance }, trove: Trove) -> ()) -> Trove,
	},
}
