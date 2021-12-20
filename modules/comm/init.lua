-- Comm
-- Stephen Leitnick
-- August 05, 2021


--[=[
	@class Comm
	Remote communication library.

	This exposes the raw functions that are used by the `ServerComm` and `ClientComm` classes.
	Those two classes should be preferred over accessing the functions directly through this
	Comm library.
]=]
local Comm = {
	Server = require(script.Server),
	Client = require(script.Client),
	ServerComm = require(script.Server.ServerComm),
	ClientComm = require(script.Client.ClientComm),
}

--[=[
	@within Comm
	@prop ServerComm ServerComm
]=]
--[=[
	@within Comm
	@prop ClientComm ClientComm
]=]

return Comm
