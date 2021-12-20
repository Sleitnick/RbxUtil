-- Comm
-- Stephen Leitnick
-- August 05, 2021

--[[

	CORE FUNCTIONS:

		Comm.Server.BindFunction(parent: Instance, name: string, func: (Instance, ...any) -> ...any, middleware): RemoteFunction
		Comm.Server.WrapMethod(parent: Instance, tbl: {}, name: string, inbound: ServerMiddleware?, outbound: ServerMiddleware?): RemoteFunction
		Comm.Server.CreateSignal(parent: Instance, name: string, inbound: ServerMiddleware?, outbound: ServerMiddleware?): RemoteSignal

		Comm.Client.GetFunction(parent: Instance, name: string, usePromise: boolean, middleware: ClientMiddleware?): (...any) -> ...any
		Comm.Client.GetSignal(parent: Instance, name: string, inbound: ClientMiddleware?, outbound: ClientMiddleware?): ClientRemoteSignal


	HELPER CLASSES:

		serverComm = Comm.Server.ForParent(parent: Instance, namespace: string?): ServerComm
		serverComm:BindFunction(name: string, func: (Instance, ...any) -> ...any, inbound: ServerMiddleware?, outbound: ServerMiddleware?): RemoteFunction
		serverComm:WrapMethod(tbl: {}, name: string, inbound: ServerMiddleware?, outbound: ServerMiddleware?): RemoteFunction
		serverComm:CreateSignal(name: string, inbound: ServerMiddleware?, outbound: ServerMiddleware?): RemoteSignal

		serverComm:Destroy()

		clientComm = Comm.Client.ForParent(parent: Instance, usePromise: boolean, namespace: string?): ClientComm
		clientComm:GetFunction(name: string, usePromise: boolean, inbound: ClientMiddleware?, outbound: ClientMiddleware?): (...any) -> ...any
		clientComm:GetSignal(name: string, inbound: ClientMiddleware?, outbound: ClientMiddleware?): ClientRemoteSignal
		clientComm:Destroy()

--]]


type FnBind = (Instance, ...any) -> ...any
type Args = {
	n: number,
	[any]: any,
}

type ServerMiddlewareFn = (Instance, Args) -> (boolean, ...any)
type ServerMiddleware = {ServerMiddlewareFn}

type ClientMiddlewareFn = (Args) -> (boolean, ...any)
type ClientMiddleware = {ClientMiddlewareFn}


local Signal = require(script.Parent.Signal)
local Option = require(script.Parent.Option)
local Promise = require(script.Parent.Promise)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local None = newproxy()

local IS_SERVER = RunService:IsServer()
local DEFAULT_COMM_FOLDER_NAME = "__comm__"
local WAIT_FOR_CHILD_TIMEOUT = 60


local function GetCommSubFolder(parent: Instance, subFolderName: string): Option.Option
	local subFolder: Instance = nil
	if IS_SERVER then
		subFolder = parent:FindFirstChild(subFolderName)
		if not subFolder then
			subFolder = Instance.new("Folder")
			subFolder.Name = subFolderName
			subFolder.Parent = parent
		end
	else
		subFolder = parent:WaitForChild(subFolderName, WAIT_FOR_CHILD_TIMEOUT)
	end
	return Option.Wrap(subFolder)
end


--[=[
	@class RemoteSignal
	@server
	Created via `ServerComm:CreateSignal()`.
]=]
local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

--[=[
	@within RemoteSignal
	@interface Connection
	.Disconnect () -> nil
]=]

function RemoteSignal.new(parent: Instance, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	local self = setmetatable({}, RemoteSignal)
	self._re = Instance.new("RemoteEvent")
	self._re.Name = name
	self._re.Parent = parent
	if outboundMiddleware and #outboundMiddleware > 0 then
		self._hasOutbound = true
		self._outbound = outboundMiddleware
	else
		self._hasOutbound = false
	end
	if inboundMiddleware and #inboundMiddleware > 0 then
		self._directConnect = false
		self._signal = Signal.new()
		self._re.OnServerEvent:Connect(function(player, ...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(player, args))
				if not middlewareResult[1] then
					return
				end
			end
			self._signal:Fire(player, table.unpack(args, 1, args.n))
		end)
	else
		self._directConnect = true
	end
	return self
end

--[=[
	@param fn (player: Player, ...: any) -> nil -- The function to connect
	@return Connection
	Connect a function to the signal. Anytime a matching ClientRemoteSignal
	on a client fires, the connected function will be invoked with the
	arguments passed by the client.
]=]
function RemoteSignal:Connect(fn)
	if self._directConnect then
		return self._re.OnServerEvent:Connect(fn)
	else
		return self._signal:Connect(fn)
	end
end

function RemoteSignal:_processOutboundMiddleware(player: Player?, ...: any)
	if not self._hasOutbound then
		return ...
	end
	local args = table.pack(...)
	for _,middlewareFunc in ipairs(self._outbound) do
		local middlewareResult = table.pack(middlewareFunc(player, args))
		if not middlewareResult[1] then
			return table.unpack(middlewareResult, 2, middlewareResult.n)
		end
	end
	return table.unpack(args, 1, args.n)
end

--[=[
	@param player Player -- The target client
	@param ... any -- Arguments passed to the client
	Fires the signal at the specified client with any arguments.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware before being
	sent to the client.
	:::
]=]
function RemoteSignal:Fire(player: Player, ...: any)
	self._re:FireClient(player, self:_processOutboundMiddleware(player, ...))
end

--[=[
	@param ... any
	Fires the signal at _all_ clients with any arguments.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware before being
	sent to the clients.
	:::
]=]
function RemoteSignal:FireAll(...: any)
	self._re:FireAllClients(self:_processOutboundMiddleware(nil, ...))
end

--[=[
	@param ignorePlayer Player -- The client to ignore
	@param ... any -- Arguments passed to the other clients
	Fires the signal to all clients _except_ the specified
	client.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware before being
	sent to the client.
	:::
]=]
function RemoteSignal:FireExcept(ignorePlayer: Player, ...: any)
	self:FireFilter(function(plr)
		return plr ~= ignorePlayer
	end, ...)
end

--[=[
	@param predicate (player: Player, argsFromFire: ...) -> boolean
	@param ... any -- Arguments to pass to the clients (and to the predicate)
	Fires the signal at any clients that pass the `predicate`
	function test. This can be used to fire signals with much
	more control logic.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware before being
	sent to the clients.
	:::

	:::caution Predicate Before Middleware
	The arguments sent to the predicate are sent _before_ getting
	transformed by any middleware.
	:::

	```lua
	-- Fire signal to players of the same team:
	remoteSignal:FireFilter(function(player)
		return player.Team.Name == "Best Team"
	end)
	```
]=]
function RemoteSignal:FireFilter(predicate: (Player, ...any) -> boolean, ...: any)
	for _,player in ipairs(Players:GetPlayers()) do
		if predicate(player, ...) then
			self._re:FireClient(player, self:_processOutboundMiddleware(nil, ...))
		end
	end
end

--[=[
	Destroys the RemoteSignal object.
]=]
function RemoteSignal:Destroy()
	self._re:Destroy()
	if self._signal then
		self._signal:Destroy()
	end
end


--[=[
	@class ClientRemoteSignal
	@client
	Created via `ClientComm:GetSignal()`.
]=]
local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

--[=[
	@within ClientRemoteSignal
	@interface Connection
	.Disconnect () -> nil
]=]

function ClientRemoteSignal.new(re: RemoteEvent, inboundMiddleware: ClientMiddleware?, outboudMiddleware: ClientMiddleware?)
	local self = setmetatable({}, ClientRemoteSignal)
	self._re = re
	if outboudMiddleware and #outboudMiddleware > 0 then
		self._hasOutbound = true
		self._outbound = outboudMiddleware
	else
		self._hasOutbound = false
	end
	if inboundMiddleware and #inboundMiddleware > 0 then
		self._directConnect = false
		self._signal = Signal.new(nil)
		self._reConn = self._re.OnClientEvent:Connect(function(...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(args))
				if not middlewareResult[1] then
					return
				end
			end
			self._signal:Fire(table.unpack(args, 1, args.n))
		end)
	else
		self._directConnect = true
	end
	return self
end

function ClientRemoteSignal:_processOutboundMiddleware(...: any)
	local args = table.pack(...)
	for _,middlewareFunc in ipairs(self._outbound) do
		local middlewareResult = table.pack(middlewareFunc(args))
		if not middlewareResult[1] then
			return table.unpack(middlewareResult, 2, middlewareResult.n)
		end
	end
	return table.unpack(args, 1, args.n)
end

--[=[
	@param fn (...: any) -> any
	@return Connection
	Connects a function to the remote signal. The function will be
	called anytime the equivalent server-side RemoteSignal is
	fired at this specific client that created this client signal.
]=]
function ClientRemoteSignal:Connect(fn)
	if self._directConnect then
		return self._re.OnClientEvent:Connect(fn)
	else
		return self._signal:Connect(fn)
	end
end

--[=[
	@param ... any -- Arguments to pass to the server
	Fires the equivalent server-side signal with the given arguments.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware before being
	sent to the server.
	:::
]=]
function ClientRemoteSignal:Fire(...: any)
	if self._hasOutbound then
		self._re:FireServer(self:_processOutboundMiddleware(...))
	else
		self._re:FireServer(...)
	end
end

--[=[
	Destroys the ClientRemoteSignal object.
]=]
function ClientRemoteSignal:Destroy()
	if self._signal then
		self._signal:Destroy()
	end
end


--[=[
	@class RemoteProperty
	@server
	Created via `ServerComm:CreateProperty()`.

	Values set can be anything that can pass through a
	[RemoteEvent](https://developer.roblox.com/en-us/articles/Remote-Functions-and-Events#parameter-limitations).

	:::caution Network
	Calling any of the data setter methods (e.g. `Set()`) will
	fire the underlying RemoteEvent to replicate data to the
	clients. Therefore, setting data should only occur when it
	is necessary to change the data that the clients receive.
	:::

	:::caution Tables
	Tables _can_ be used with RemoteProperties. However, the
	RemoteProperty object will _not_ watch for changes within
	the table. Therefore, anytime changes are made to the table,
	the data must be set again using one of the setter methods.
	:::
]=]
local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty

function RemoteProperty.new(parent: Instance, name: string, initialValue: any, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	local self = setmetatable({}, RemoteProperty)
	self._rs = RemoteSignal.new(parent, name, inboundMiddleware, outboundMiddleware)
	self._value = initialValue
	self._perPlayer = {}
	self._playerRemoving = Players.PlayerRemoving:Connect(function(player)
		self._perPlayer[player] = nil
	end)
	self._rs:Connect(function(player)
		local playerValue = self._perPlayer[player]
		local value = if playerValue == nil then self._value elseif playerValue == None then nil else playerValue
		self._rs:Fire(player, value)
	end)
	return self
end

--[=[
	@param value any
	Sets the top-level value of all clients to the same value.
	
	:::note Override Per-Player Data
	This will override any per-player data that was set using
	`SetFor` or `SetFilter`. To avoid overriding this data,
	`SetTop` can be used instead.
	:::

	```lua
	-- Examples
	remoteProperty:Set(10)
	remoteProperty:Set({SomeData = 32})
	remoteProperty:Set("HelloWorld")
	```
]=]
function RemoteProperty:Set(value: any)
	self._value = value
	table.clear(self._perPlayer)
	self._rs:FireAll(value)
end

--[=[
	@param value any
	Set the top-level value of the property, but does not override
	any per-player data (e.g. set with `SetFor` or `SetFilter`).
	Any player without custom-set data will receive this new data.

	This is useful if certain players have specific values that
	should not be changed, but all other players should receive
	the same new value.

	```lua
	-- Using just 'Set' overrides per-player data:
	remoteProperty:SetFor(somePlayer, "CustomData")
	remoteProperty:Set("Data")
	print(remoteProperty:GetFor(somePlayer)) --> "Data"

	-- Using 'SetTop' does not override:
	remoteProperty:SetFor(somePlayer, "CustomData")
	remoteProperty:SetTop("Data")
	print(remoteProperty:GetFor(somePlayer)) --> "CustomData"
	```
]=]
function RemoteProperty:SetTop(value: any)
	self._value = value
	for _,player in ipairs(Players:GetPlayers()) do
		if self._perPlayer[player] == nil then
			self._rs:Fire(player, value)
		end
	end
end

--[=[
	@param predicate (player: Player, value: any) -> boolean
	@param value any -- Value to set for the clients (and to the predicate)
	Fires the signal at any clients that pass the `predicate`
	function test. This can be used to fire signals with much
	more control logic.

	```lua
	-- Set the value of "NewValue" to players with a name longer than 10 characters:
	remoteProperty:SetFilter(function(player)
		return #player.Name > 10
	end, "NewValue")
	```
]=]
function RemoteProperty:SetFilter(predicate: (Player, any) -> boolean, value: any)
	for _,player in ipairs(Players:GetPlayers()) do
		if predicate(player, value) then
			self:SetFor(player, value)
		end
	end
end

--[=[
	@param player Player
	@param value any
	Set the value of the property for a specific player. This
	will override the value used by `Set` (and the initial value
	set for the property when created).

	This value _can_ be `nil`. In order to reset the value for a
	given player and let the player use the top-level value held
	by this property, either use `Set` to set all players' data,
	or use `ClearFor`.

	```lua
	remoteProperty:SetFor(somePlayer, "CustomData")
	```
]=]
function RemoteProperty:SetFor(player: Player, value: any)
	if player.Parent then
		self._perPlayer[player] = if value == nil then None else value
	end
	self._rs:Fire(player, value)
end

--[=[
	@param player Player
	Clears the custom property value for the given player. When
	this occurs, the player will reset to use the top-level
	value held by this property (either the value set when the
	property was created, or the last value set by `Set`).

	```lua
	remoteProperty:Set("DATA")

	remoteProperty:SetFor(somePlayer, "CUSTOM_DATA")
	print(remoteProperty:GetFor(somePlayer)) --> "CUSTOM_DATA"

	-- DOES NOT CLEAR, JUST SETS CUSTOM DATA TO NIL:
	remoteProperty:SetFor(somePlayer, nil)
	print(remoteProperty:GetFor(somePlayer)) --> nil

	-- CLEAR:
	remoteProperty:ClearFor(somePlayer)
	print(remoteProperty:GetFor(somePlayer)) --> "DATA"
	```
]=]
function RemoteProperty:ClearFor(player: Player)
	if self._perPlayer[player] == nil then return end
	self._perPlayer[player] = nil
	self._rs:Fire(player, self._value)
end

--[=[
	@return any
	Returns the top-level value held by the property. This will
	either be the initial value set, or the last value set
	with `Set()`.

	```lua
	remoteProperty:Set("Data")
	print(remoteProperty:Get()) --> "Data"
	```
]=]
function RemoteProperty:Get(): any
	return self._value
end

--[=[
	@return any
	Returns the current value for the given player. This value
	will depend on if `SetFor` or `SetFilter` has affected the
	custom value for the player. If so, that custom value will
	be returned. Otherwise, the top-level value will be used
	(e.g. value from `Set`).

	```lua
	-- Set top level data:
	remoteProperty:Set("Data")
	print(remoteProperty:GetFor(somePlayer)) --> "Data"

	-- Set custom data:
	remoteProperty:SetFor(somePlayer, "CustomData")
	print(remoteProperty:GetFor(somePlayer)) --> "CustomData"

	-- Set top level again, overriding custom data:
	remoteProperty:Set("NewData")
	print(remoteProperty:GetFor(somePlayer)) --> "NewData"

	-- Set custom data again, and set top level without overriding:
	remoteProperty:SetFor(somePlayer, "CustomData")
	remoteProperty:SetTop("Data")
	print(remoteProperty:GetFor(somePlayer)) --> "CustomData"

	-- Clear custom data to use top level data:
	remoteProperty:ClearFor(somePlayer)
	print(remoteProperty:GetFor(somePlayer)) --> "Data"
	```
]=]
function RemoteProperty:GetFor(player: Player): any
	local playerValue = self._perPlayer[player]
	local value = if playerValue == nil then self._value elseif playerValue == None then nil else playerValue
	return value
end

--[=[
	Destroys the RemoteProperty object.
]=]
function RemoteProperty:Destroy()
	self._rs:Destroy()
	self._playerRemoving:Disconnect()
end


--[=[
	@class ClientRemoteProperty
	@client
	Created via `ClientComm:GetProperty()`.
]=]
local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

function ClientRemoteProperty.new(re: RemoteEvent, inboundMiddleware: ClientMiddleware?, outboudMiddleware: ClientMiddleware?)
	local self = setmetatable({}, ClientRemoteProperty)
	self._rs = ClientRemoteSignal.new(re, inboundMiddleware, outboudMiddleware)
	self._ready = false
	self._value = nil
	self.Changed = self._rs
	self._changed = self._rs:Connect(function(value)
		self._value = value
	end)
	self._readyPromise = self:OnReady():andThen(function()
		self._readyPromise = nil
	end)
	self._rs:Fire()
	return self
end

--[=[
	@return any
	Gets the value of the property object.

	:::caution
	This value might not be ready right away. Use `OnReady()` or `IsReady()`
	before calling `Get()`.
	:::
]=]
function ClientRemoteProperty:Get()
	return self._value
end

--[=[
	@return Promise<any>
	Returns a Promise which resolves once the property object is
	ready to be used. The resolved promise will also contain the
	value of the property.

	```lua
	-- Use andThen clause:
	clientRemoteProperty:OnReady():andThen(function(initialValue)
		print(initialValue)
	end)

	-- Use await:
	local success, initialValue = clientRemoteProperty:OnReady():await()
	if success then
		print(initialValue)
	end
	```
]=]
function ClientRemoteProperty:OnReady()
	if self._ready then
		return Promise.resolve(self._value)
	end
	return Promise.fromEvent(self._rs, function(value)
		self._value = value
		self._ready = true
		return true
	end):andThen(function()
		return self._value
	end)
end

--[=[
	@return boolean
	Returns `true` if the property object is ready to be
	used. In other words, it has successfully gained
	connection to the server-side version and has synced
	in the initial value.

	```lua
	if clientRemoteProperty:IsReady() then
		local value = clientRemoteProperty:Get()
	end
	```
]=]
function ClientRemoteProperty:IsReady(): boolean
	return self._ready
end

--[=[
	@param observer (any) -> nil
	@return Connection
	Observes the value of the property. The observer will
	be called right when the value is first ready, and
	every time the value changes. This is safe to call
	immediately (i.e. no need to use `IsReady` or `OnReady`
	before using this method).

	```lua
	local function ObserveValue(value)
		print(value)
	end

	clientRemoteProperty:Observe(ObserveValue)
	```
]=]
function ClientRemoteProperty:Observe(observer: (any) -> nil)
	if self._ready then
		task.defer(observer, self._value)
	end
	return self.Changed:Connect(observer)
end

--[=[
	Destroys the ClientRemoteProperty object.
]=]
function ClientRemoteProperty:Destroy()
	self._rs:Destroy()
	if self._readyPromise then
		self._readyPromise:cancel()
	end
	self._changed:Disconnect()
end


--[=[
	@class Comm
	Remote communication library.

	This exposes the raw functions that are used by the `ServerComm` and `ClientComm` classes.
	Those two classes should be preferred over accessing the functions directly through this
	Comm library.
]=]
local Comm = {Server = {}, Client = {}}

--[=[
	@within Comm
	@prop ServerComm ServerComm
]=]
--[=[
	@within Comm
	@prop ClientComm ClientComm
]=]

--[=[
	@within Comm
	@private
	@interface Server
	.BindFunction (parent: Instance, name: string, fn: FnBind, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteFunction
	.WrapMethod (parent: Instance, tbl: table, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteFunction
	.CreateSignal (parent: Instance, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteSignal
	.CreateProperty (parent: Instance, name: string, value: any, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteProperty
	Server Comm
]=]
--[=[
	@within Comm
	@private
	@interface Client
	.GetFunction (parent: Instance, name: string, usePromise: boolean, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?): (...: any) -> any
	.GetSignal (parent: Instance, name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?): ClientRemoteSignal
	.GetProperty (parent: Instance, name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?): ClientRemoteProperty
	Client Comm
]=]


function Comm.Server.BindFunction(parent: Instance, name: string, func: FnBind, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteFunction
	assert(IS_SERVER, "BindFunction must be called from the server")
	local folder = GetCommSubFolder(parent, "RF"):Expect("Failed to get Comm RF folder")
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	local hasInbound = type(inboundMiddleware) == "table" and #inboundMiddleware > 0
	local hasOutbound = type(outboundMiddleware) == "table" and #outboundMiddleware > 0
	local function ProcessOutbound(player, ...)
		local args = table.pack(...)
		for _,middlewareFunc in ipairs(outboundMiddleware) do
			local middlewareResult = table.pack(middlewareFunc(player, args))
			if not middlewareResult[1] then
				return table.unpack(middlewareResult, 2, middlewareResult.n)
			end
		end
		return table.unpack(args, 1, args.n)
	end
	if hasInbound and hasOutbound then
		local function OnServerInvoke(player, ...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(player, args))
				if not middlewareResult[1] then
					return table.unpack(middlewareResult, 2, middlewareResult.n)
				end
			end
			return ProcessOutbound(player, func(player, table.unpack(args, 1, args.n)))
		end
		rf.OnServerInvoke = OnServerInvoke
	elseif hasInbound then
		local function OnServerInvoke(player, ...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(player, args))
				if not middlewareResult[1] then
					return table.unpack(middlewareResult, 2, middlewareResult.n)
				end
			end
			return func(player, table.unpack(args, 1, args.n))
		end
		rf.OnServerInvoke = OnServerInvoke
	elseif hasOutbound then
		local function OnServerInvoke(player, ...)
			return ProcessOutbound(player, func(player, ...))
		end
		rf.OnServerInvoke = OnServerInvoke
	else
		rf.OnServerInvoke = func
	end
	rf.Parent = folder
	return rf
end


function Comm.Server.WrapMethod(parent: Instance, tbl: {}, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteFunction
	assert(IS_SERVER, "WrapMethod must be called from the server")
	local fn = tbl[name]
	assert(type(fn) == "function", "Value at index " .. name .. " must be a function; got " .. type(fn))
	return Comm.Server.BindFunction(parent, name, function(...) return fn(tbl, ...) end, inboundMiddleware, outboundMiddleware)
end


function Comm.Server.CreateSignal(parent: Instance, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	assert(IS_SERVER, "CreateSignal must be called from the server")
	local folder = GetCommSubFolder(parent, "RE"):Expect("Failed to get Comm RE folder")
	local rs = RemoteSignal.new(folder, name, inboundMiddleware, outboundMiddleware)
	return rs
end


function Comm.Server.CreateProperty(parent: Instance, name: string, initialValue: any, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	assert(IS_SERVER, "CreateProperty must be called from the server")
	local folder = GetCommSubFolder(parent, "RP"):Expect("Failed to get Comm RP folder")
	local rp = RemoteProperty.new(folder, name, initialValue, inboundMiddleware, outboundMiddleware)
	return rp
end


function Comm.Client.GetFunction(parent: Instance, name: string, usePromise: boolean, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	assert(not IS_SERVER, "GetFunction must be called from the client")
	local folder = GetCommSubFolder(parent, "RF"):Expect("Failed to get Comm RF folder")
	local rf = folder:WaitForChild(name, WAIT_FOR_CHILD_TIMEOUT)
	assert(rf ~= nil, "Failed to find RemoteFunction: " .. name)
	local hasInbound = type(inboundMiddleware) == "table" and #inboundMiddleware > 0
	local hasOutbound = type(outboundMiddleware) == "table" and #outboundMiddleware > 0
	local function ProcessOutbound(args)
		for _,middlewareFunc in ipairs(outboundMiddleware) do
			local middlewareResult = table.pack(middlewareFunc(args))
			if not middlewareResult[1] then
				return table.unpack(middlewareResult, 2, middlewareResult.n)
			end
		end
		return table.unpack(args, 1, args.n)
	end
	if hasInbound then
		if usePromise then
			return function(...)
				local args = table.pack(...)
				return Promise.new(function(resolve, reject)
					local success, res = pcall(function()
						if hasOutbound then
							return table.pack(rf:InvokeServer(ProcessOutbound(args)))
						else
							return table.pack(rf:InvokeServer(table.unpack(args, 1, args.n)))
						end
					end)
					if success then
						for _,middlewareFunc in ipairs(inboundMiddleware) do
							local middlewareResult = table.pack(middlewareFunc(res))
							if not middlewareResult[1] then
								return table.unpack(middlewareResult, 2, middlewareResult.n)
							end
						end
						resolve(table.unpack(res, 1, res.n))
					else
						reject(res)
					end
				end)
			end
		else
			return function(...)
				local res
				if hasOutbound then
					res = table.pack(rf:InvokeServer(ProcessOutbound(table.pack(...))))
				else
					res = table.pack(rf:InvokeServer(...))
				end
				for _,middlewareFunc in ipairs(inboundMiddleware) do
					local middlewareResult = table.pack(middlewareFunc(res))
					if not middlewareResult[1] then
						return table.unpack(middlewareResult, 2, middlewareResult.n)
					end
				end
				return table.unpack(res, 1, res.n)
			end
		end
	else
		if usePromise then
			return function(...)
				local args = table.pack(...)
				return Promise.new(function(resolve, reject)
					local success, res = pcall(function()
						if hasOutbound then
							return table.pack(rf:InvokeServer(ProcessOutbound(args)))
						else
							return table.pack(rf:InvokeServer(table.unpack(args, 1, args.n)))
						end
					end)
					if success then
						resolve(table.unpack(res, 1, res.n))
					else
						reject(res)
					end
				end)
			end
		else
			if hasOutbound then
				return function(...)
					return rf:InvokeServer(ProcessOutbound(table.pack(...)))
				end
			else
				return function(...)
					return rf:InvokeServer(...)
				end
			end
		end
	end
end


function Comm.Client.GetSignal(parent: Instance, name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	assert(not IS_SERVER, "GetSignal must be called from the client")
	local folder = GetCommSubFolder(parent, "RE"):Expect("Failed to get Comm RE folder")
	local re = folder:WaitForChild(name, WAIT_FOR_CHILD_TIMEOUT)
	assert(re ~= nil, "Failed to find RemoteEvent: " .. name)
	return ClientRemoteSignal.new(re, inboundMiddleware, outboundMiddleware)
end


function Comm.Client.GetProperty(parent: Instance, name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	assert(not IS_SERVER, "GetProperty must be called from the client")
	local folder = GetCommSubFolder(parent, "RP"):Expect("Failed to get Comm RP folder")
	local re = folder:WaitForChild(name, WAIT_FOR_CHILD_TIMEOUT)
	assert(re ~= nil, "Failed to find RemoteEvent for RemoteProperty: " .. name)
	return ClientRemoteProperty.new(re, inboundMiddleware, outboundMiddleware)
end


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
	@param parent Instance
	@param namespace string?
	@return ServerComm
	Constructs a ServerComm object. The `namespace` parameter is used
	in cases where more than one ServerComm object may be bound
	to the same object. Otherwise, a default namespace is used.
]=]
function ServerComm.new(parent: Instance, namespace: string?)
	assert(IS_SERVER, "ServerComm must be constructed from the server")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = DEFAULT_COMM_FOLDER_NAME
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
]=]
function ServerComm:BindFunction(name: string, func: FnBind, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteFunction
	return Comm.Server.BindFunction(self._instancesFolder, name, func, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param tbl table
	@param name string
	@param inboundMiddleware ServerMiddleware?
	@param outboundMiddleware ServerMiddleware?
	@return RemoteFunction
]=]
function ServerComm:WrapMethod(tbl: {}, name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?): RemoteFunction
	return Comm.Server.WrapMethod(self._instancesFolder, tbl, name, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param inboundMiddleware ServerMiddleware?
	@param outboundMiddleware ServerMiddleware?
	@return RemoteSignal
]=]
function ServerComm:CreateSignal(name: string, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	return Comm.Server.CreateSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
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

	local mapInfo = comm:CreateProperty({
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
function ServerComm:CreateProperty(name: string, initialValue: any, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?)
	return Comm.Server.CreateProperty(self._instanceFolder, name, initialValue, inboundMiddleware, outboundMiddleware)
end

--[=[
	Destroy the ServerComm object.
]=]
function ServerComm:Destroy()
	self._instancesFolder:Destroy()
end


--[=[
	@class ClientComm
	@client
]=]
local ClientComm = {}
ClientComm.__index = ClientComm

--[=[
	@within ClientComm
	@type ClientMiddlewareFn (args: {any}) -> (shouldContinue: boolean, ...: any)
	The middleware function takes the arguments (as a table array), and should
	return `true|false` to indicate if the process should continue.

	If returning `false`, the optional varargs after the `false` are used as the new return values
	to whatever was calling the middleware.
]=]
--[=[
	@within ClientComm
	@type ClientMiddleware {ClientMiddlewareFn}
	Array of middleware functions.
]=]

--[=[
	@param parent Instance
	@param usePromise boolean
	@param namespace string?
	@return ClientComm
	Constructs a ClientComm object.

	If `usePromise` is set to `true`, then `GetFunction` will generate a function that returns a Promise
	that resolves with the server response. If set to `false`, the function will act like a normal
	call to a RemoteFunction and yield until the function responds.
]=]
function ClientComm.new(parent: Instance, usePromise: boolean, namespace: string?, janitor)
	assert(not IS_SERVER, "ClientComm must be constructed from the client")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = DEFAULT_COMM_FOLDER_NAME
	if namespace then
		ns = namespace
	end
	local folder: Instance? = parent:WaitForChild(ns, WAIT_FOR_CHILD_TIMEOUT)
	assert(folder ~= nil, "Could not find namespace for ClientComm in parent: " .. ns)
	local self = setmetatable({}, ClientComm)
	self._instancesFolder = folder
	self._usePromise = usePromise
	if janitor then
		janitor:Add(self)
	end
	return self
end

--[=[
	@param name string
	@param inboundMiddleware ClientMiddleware?
	@param outboundMiddleware ClientMiddleware?
	@return (...: any) -> any

	Generates a function on the matching RemoteFunction generated with ServerComm. The function
	can then be called to invoke the server. If this `ClientComm` object was created with
	the `usePromise` parameter set to `true`, then this generated function will return
	a Promise when called.

	```lua
	-- Server-side:
	local serverComm = ServerComm.new(someParent)
	serverComm:BindFunction("MyFunction", function(player, msg)
		return msg:upper()
	end)

	-- Client-side:
	local clientComm = ClientComm.new(someParent)
	local myFunc = clientComm:GetFunction("MyFunction")
	local uppercase = myFunc("hello world")
	print(uppercase) --> HELLO WORLD

	-- Client-side, using promises:
	local clientComm = ClientComm.new(someParent, true)
	local myFunc = clientComm:GetFunction("MyFunction")
	myFunc("hi there"):andThen(function(msg)
		print(msg) --> HI THERE
	end):catch(function(err)
		print("Error:", err)
	end)
	```
]=]
function ClientComm:GetFunction(name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	return Comm.Client.GetFunction(self._instancesFolder, name, self._usePromise, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param inboundMiddleware ClientMiddleware?
	@param outboundMiddleware ClientMiddleware?
	@return ClientRemoteSignal
	Returns a new ClientRemoteSignal that mirrors the matching RemoteSignal created by
	ServerComm with the same matching `name`.
]=]
function ClientComm:GetSignal(name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	return Comm.Client.GetSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param inboundMiddleware ClientMiddleware?
	@param outboundMiddleware ClientMiddleware?
	@return ClientRemoteSignal
	Returns a new ClientRemoteProperty that mirrors the matching RemoteProperty created by
	ServerComm with the same matching `name`.
]=]
function ClientComm:GetProperty(name: string, inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	return Comm.Client.GetProperty(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param inboundMiddleware ClientMiddleware?
	@param outboundMiddleware ClientMiddleware?
	@return table
	Returns an object which maps RemoteFunctions as methods
	and RemoteEvents as fields.
	```lua
	-- Server-side:
	serverComm:BindFunction("Test", function(player) end)
	serverComm:CreateSignal("MySignal")

	-- Client-side
	local obj = clientComm:BuildObject()
	obj:Test()
	obj.MySignal:Connect(function() end)
	```
]=]
function ClientComm:BuildObject(inboundMiddleware: ClientMiddleware?, outboundMiddleware: ClientMiddleware?)
	local obj = {}
	local rfFolder = self._instancesFolder:FindFirstChild("RF")
	local reFolder = self._instancesFolder:FindFirstChild("RE")
	local rpFolder = self._instancesFolder:FindFirstChild("RP")
	if rfFolder then
		for _,rf in ipairs(rfFolder:GetChildren()) do
			if not rf:IsA("RemoteFunction") then continue end
			local f = self:GetFunction(rf.Name, inboundMiddleware, outboundMiddleware)
			obj[rf.Name] = function(_self, ...)
				return f(...)
			end
		end
	end
	if reFolder then
		for _,re in ipairs(reFolder:GetChildren()) do
			if not re:IsA("RemoteEvent") then continue end
			obj[re.Name] = self:GetSignal(re.Name, inboundMiddleware, outboundMiddleware)
		end
	end
	if rpFolder then
		for _,re in ipairs(rpFolder:GetChildren()) do
			if not re:IsA("RemoteEvent") then continue end
			obj[re.Name] = self:GetProperty(re.Name, inboundMiddleware, outboundMiddleware)
		end
	end
	return obj
end

--[=[
	Destroys the ClientComm object.
]=]
function ClientComm:Destroy()
end


Comm.ServerComm = ServerComm
Comm.ClientComm = ClientComm


return Comm
