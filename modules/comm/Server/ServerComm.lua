-- ServerComm
-- Stephen Leitnick
-- December 20, 2021

local Comm = require(script.Parent)
local Util = require(script.Parent.Parent.Util)
local Types = require(script.Parent.Parent.Types)

--[=[
	@class ServerComm
	@server
]=]
local ServerComm = {}
ServerComm.__index = ServerComm

--[=[
	@within ServerComm
	@type ServerMiddlewareFn (player: Player, args: {any}) -> (shouldContinue: boolean, ...: any)
	The middleware function takes the client player and the arguments (as a table array), and should
	return `true|false` to indicate if the process should continue.

	If returning `false`, the optional varargs after the `false` are used as the new return values
	to whatever was calling the middleware.
]=]
--[=[
	@within ServerComm
	@type ServerMiddleware {ServerMiddlewareFn}
	Array of middleware functions.
]=]

--[=[
	@return ServerComm
	Constructs a ServerComm object. The `namespace` parameter is used
	in cases where more than one ServerComm object may be bound
	to the same object. Otherwise, a default namespace is used.

	```lua
	local serverComm = ServerComm.new(game:GetService("ReplicatedStorage"))

	-- If many might exist in the given parent, use a unique namespace:
	local serverComm = ServerComm.new(game:GetService("ReplicatedStorage"), "MyNamespace")
	```
]=]
function ServerComm.new(parent: Instance, namespace: string?)
	assert(Util.IsServer, "ServerComm must be constructed from the server")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = Util.DefaultCommFolderName
	if namespace then
		ns = namespace
	end
	assert(not parent:FindFirstChild(ns), "Parent already has another ServerComm bound to namespace " .. ns)
	local self = setmetatable({}, ServerComm)
	self._instancesFolder = Instance.new("Folder")
	self._instancesFolder.Name = ns
	self._instancesFolder.Parent = parent
	return self
end

--[=[
	@param name string
	@param fn (player: Player, ...: any) -> ...: any
	@param inboundMiddleware ServerMiddleware?
	@param outboundMiddleware ServerMiddleware?
	@return RemoteFunction
	Creates a RemoteFunction and binds the given function to it. Inbound
	and outbound middleware can be applied if desired.

	```lua
	local function GetSomething(player: Player)
		return "Something"
	end

	serverComm:BindFunction("GetSomething", GetSomething)
	```
]=]
function ServerComm:BindFunction(
	name: string,
	fn: Types.FnBind,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
): RemoteFunction
	return Comm.BindFunction(self._instancesFolder, name, fn, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param tbl table
	@param name string
	@param inboundMiddleware ServerMiddleware?
	@param outboundMiddleware ServerMiddleware?
	@return RemoteFunction

	Binds a function to a table method. The name must match the
	name of the method in the table. The same name will be used
	on the client to access the given function.

	```lua
	local MyObject = {
		_Data = 10,
	}

	function MyObject:GetData(player: Player)
		return self._Data
	end

	serverComm:WrapMethod(MyObject, "GetData")
	```
]=]
function ServerComm:WrapMethod(
	tbl: {},
	name: string,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
): RemoteFunction
	return Comm.WrapMethod(self._instancesFolder, tbl, name, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param inboundMiddleware ServerMiddleware?
	@param outboundMiddleware ServerMiddleware?
	@return RemoteSignal

	Creates a signal that can be used to fire data to the clients
	or receive data from the clients.

	```lua
	local mySignal = serverComm:CreateSignal("MySignal")

	-- Examples of firing in different ways (see docs for RemoteSignal for further info):
	mySignal:Fire(somePlayer, "Hello world")
	mySignal:FireAll("Hi there")
	mySignal:FireExcept(somePlayer, "Hello everyone except " .. somePlayer.Name)
	mySignal:FireFilter(function(player) return player.Team == someCoolTeam end, "Hello cool team")

	-- Example of listening for clients to send data:
	mySignal:Connect(function(player, message)
		print("Got a message from " .. player.Name .. ":", message)
	end)
	```
]=]
function ServerComm:CreateSignal(
	name: string,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
)
	return Comm.CreateSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param initialValue any
	@param inboundMiddleware ServerMiddleware?
	@param outboundMiddleware ServerMiddleware?
	@return RemoteProperty

	Create a property object which will replicate its property value to
	the clients. Optionally, specific clients can be targeted with
	different property values.

	```lua
	local comm = Comm.ServerComm.new(game:GetService("ReplicatedStorage"))

	local mapInfo = comm:CreateProperty("MapInfo", {
		MapName = "TheAwesomeMap",
		MapDuration = 60,
	})

	-- Change the data:
	mapInfo:Set({
		MapName = "AnotherMap",
		MapDuration = 30,
	})

	-- Change the data for one player:
	mapInfo:SetFor(somePlayer, {
		MapName = "ASpecialMapForYou",
		MapDuration = 90,
	})

	-- Change data based on a predicate function:
	mapInfo:SetFilter(function(player)
		return player.Team == game.Teams.SomeSpecialTeam
	end, {
		MapName = "TeamMap",
		MapDuration = 20,
	})
	```
]=]
function ServerComm:CreateProperty(
	name: string,
	initialValue: any,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
)
	return Comm.CreateProperty(self._instancesFolder, name, initialValue, inboundMiddleware, outboundMiddleware)
end

--[=[
	Destroy the ServerComm object.
]=]
function ServerComm:Destroy()
	self._instancesFolder:Destroy()
end

return ServerComm
