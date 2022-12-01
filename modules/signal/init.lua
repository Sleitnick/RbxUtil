-- Signal
-- MaximumADHD
-- November 29th, 2022

--!strict

local SignalApi: any = require(script.SignalApi)

export type Connection = {
	Connected: boolean,
	Disconnect: (Connection) -> (),
	Destroy: (Connection) -> (),
}

export type ClassType = {
	Connect: (self: ClassType, func: (...any) -> ()) -> Connection,
	ConnectOnce: (self: ClassType, func: (...any) -> ()) -> Connection,
	Once: (self: ClassType, func: (...any) -> ()) -> Connection,
	GetConnections: (self: ClassType) -> { Connection },
	DisconnectAll: (self: ClassType) -> (),
	Fire: <T...>(self: ClassType, T...) -> (),
	FireDeferred: <T...>(self: ClassType, T...) -> (),
	Wait: <T...>(self: ClassType) -> (T...),
	Destroy: (self: ClassType) -> (),
}

-- stylua: ignore
return SignalApi :: {
	new: () -> ClassType,
	Is: (object: any) -> boolean,
	Wrap: (signal: RBXScriptSignal) -> ClassType,
}