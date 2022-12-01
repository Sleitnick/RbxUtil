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

export type Signal = {
	Connect: (self: Signal, func: (...any) -> ()) -> Connection,
	ConnectOnce: (self: Signal, func: (...any) -> ()) -> Connection,
	Once: (self: Signal, func: (...any) -> ()) -> Connection,
	GetConnections: (self: Signal) -> { Connection },
	DisconnectAll: (self: Signal) -> (),
	Fire: <T...>(self: Signal, T...) -> (),
	FireDeferred: <T...>(self: Signal, T...) -> (),
	Wait: <T...>(self: Signal) -> (T...),
	Destroy: (self: Signal) -> (),
}

-- stylua: ignore
return SignalApi :: {
	new: () -> Signal,
	Is: (object: any) -> boolean,
	Wrap: (signal: RBXScriptSignal) -> Signal,
}