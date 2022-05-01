-- Comm
-- Stephen Leitnick
-- August 05, 2021


--[=[
	@class Comm
	Remote communication library.

	This exposes the raw functions that are used by the `ServerComm` and `ClientComm` classes.
	Those two classes should be preferred over accessing the functions directly through this
	Comm library.

	```lua
	-- Server
	local ServerComm = require(ReplicatedStorage.Packages.Comm).ServerComm
	local serverComm = ServerComm.new(somewhere, "MyComm")
	serverComm:BindFunction("Hello", function(player: Player)
		return "Hi"
	end)
	
	-- Client
	local ClientComm = require(ReplicatedStorage.Packages.Comm).ClientComm
	local clientComm = ClientComm.new(somewhere, false, "MyComm")
	local comm = clientComm:BuildObject()
	print(comm:Hello()) --> Hi
	```
]=]
local Comm = {
	Server = require(script.Server),
	Client = require(script.Client),
	ServerComm = require(script.Server.ServerComm),
	ClientComm = require(script.Client.ClientComm),
}

return Comm
