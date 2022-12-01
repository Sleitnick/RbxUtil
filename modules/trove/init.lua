-- Trove
-- Rocky28447
-- November 30th, 2022

--!strict

local TroveApi = require(script.TroveApi)
local Promise = require(script.Parent.Promise)

type Promise = Promise.Class

export type Trove = {
	Extend: (self: Trove) -> Trove,
	Clone: (self: Trove, instance: Instance) -> Instance,
	Construct: (<T>(self: Trove, createFunc: (...any) -> ...any, ...any) -> T) & (<T>(self: Trove, classTable: { new: (...any) -> ...any }, ...any) -> T),
	Connect: (signal: RBXScriptSignal, fn: (...any) -> ()) -> RBXScriptConnection,
	BindToRenderStep: (name: string, priority: number, fn: (dt: number) -> ()) -> (),
	AddPromise: (promise: Promise) -> Promise,
	Add: (object: any, cleanupMethod: string?) -> any,
	Remove: (object: any) -> boolean,
	Clean: () -> (),
	AttachToInstance: (instance: Instance) -> RBXScriptConnection,
	Destroy: () -> (),
}

return TroveApi :: {
	new: () -> Trove,
}
