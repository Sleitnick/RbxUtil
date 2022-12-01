-- Streamable
-- Rocky28447
-- November 30th, 2022

--!strict

local StreamableApi: any = require(script.Streamable)
local StreamableUtilApi: any = require(script.StreamableUtil)

local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)

type Connection = Signal.Connection
type Signal = Signal.ClassType
type Trove = Trove.ClassType

export type ClassType = {
	Observe: (self: ClassType, handler: (instance: Instance, trove: Trove) -> ()) -> Connection,
	Destroy: (self: ClassType) -> (),
}

return {
	Streamable = StreamableApi,
	StreamableUtil = StreamableUtilApi,
} :: {
	Streamable: {
		new: (parent: Instance, childName: string) -> ClassType,
		primary: (parent: Model) -> ClassType,
	},

	StreamableUtil: {
		Compound: (streamables: { ClassType }, handler: ({ [string]: Instance }, trove: Trove) -> ()) -> Trove,
	},
}
