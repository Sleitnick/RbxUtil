-- RemoteSignal
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteSignal = RemoteSignal.new()

	remoteSignal:Connect(handler: (player: Player, ...args: any) -> void): RBXScriptConnection
	remoteSignal:Fire(player: Player, ...args: any): void
	remoteSignal:FireAll(...args: any): void
	remoteSignal:FireExcept(player: Player, ...args: any): void
	remoteSignal:Wait(): (...any)
	remoteSignal:Destroy(): void

--]]


local IS_SERVER = game:GetService("RunService"):IsServer()

local Players = game:GetService("Players")

local Ser = require(script.Parent.Parent.Ser)

--[=[
	@class RemoteSignal
	@server
	Represents a remote signal.
	```lua
	local RemoteSignal = require(packages.Remote).RemoteSignal
	```
]=]
local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal


--[=[
	@param object any
	@return boolean
	Returns `true` if `object` is a RemoteSignal.
]=]
function RemoteSignal.Is(object)
	return type(object) == "table" and getmetatable(object) == RemoteSignal
end


--[=[
	@return RemoteSignal
	Constructs a new RemoteSignal.
]=]
function RemoteSignal.new()
	assert(IS_SERVER, "RemoteSignal can only be created on the server")
	local self = setmetatable({
		_remote = Instance.new("RemoteEvent");
	}, RemoteSignal)
	return self
end


--[=[
	@param player Player
	@param ... any
	@return RemoteSignal
	Fires the signal for the given player with any number of arguments.
]=]
function RemoteSignal:Fire(player, ...)
	self._remote:FireClient(player, Ser.SerializeArgsAndUnpack(...))
end


--[=[
	@param ... any
	@return RemoteSignal
	Fires the signal for all players with any number of arguments.
]=]
function RemoteSignal:FireAll(...)
	self._remote:FireAllClients(Ser.SerializeArgsAndUnpack(...))
end


--[=[
	@param player Player
	@param ... any
	@return RemoteSignal
	Fires the signal for all players (_except_ `player`) with any number of arguments.
]=]
function RemoteSignal:FireExcept(player, ...)
	local args = Ser.SerializeArgs(...)
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			self._remote:FireClient(plr, Ser.UnpackArgs(args))
		end
	end
end


--[=[
	@return ...: any
	@yields
	Waits for the signal to be fired and then returns the arguments.
]=]
function RemoteSignal:Wait()
	return self._remote.OnServerEvent:Wait()
end


--[=[
	@param handler (player: Player, args: ...any) -> nil
	@return RBXScriptConnection
	Connects a function to the signal, which will be fired
	anytime a client fires the signal.
]=]
function RemoteSignal:Connect(handler)
	return self._remote.OnServerEvent:Connect(function(player, ...)
		handler(player, Ser.DeserializeArgsAndUnpack(...))
	end)
end


--[=[
	Destroys the signal.
]=]
function RemoteSignal:Destroy()
	self._remote:Destroy()
	self._remote = nil
end


return RemoteSignal
