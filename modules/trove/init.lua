-- Trove
-- Rocky28447
-- November 30th, 2022

--!strict

local TroveApi = require(script.TroveApi)
local _Promise = require(script.Parent.Promise)

-- this will have to wait until PR on the Promise repo gets approved
-- type Promise = Promise.ClassType
type Promise = any

export type ClassType = {
	Extend: (self: ClassType) -> ClassType,
	Clone: (self: ClassType, instance: Instance) -> Instance,
	Construct: (<T>(self: ClassType, createFunc: (...any) -> ...any, ...any) -> T)
		& (<T>(self: ClassType, classTable: { new: (...any) -> ...any }, ...any) -> T),
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
	new: () -> ClassType,
}
