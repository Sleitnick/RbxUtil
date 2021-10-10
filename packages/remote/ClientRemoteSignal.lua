-- ClientRemoteSignal
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteSignal = ClientRemoteSignal.new(remoteEvent: RemoteEvent)

	remoteSignal:Connect(handler: (...args: any)): Connection
	remoteSignal:Fire(...args: any): void
	remoteSignal:Wait(): (...any)
	remoteSignal:Destroy(): void

--]]


local IS_SERVER = game:GetService("RunService"):IsServer()

local Ser = require(script.Parent.Parent.Ser)

-- ------------------------------------------------------------
-- Connection

local Connection = {}
Connection.__index = Connection

function Connection.new(event, connection)
	local self = setmetatable({
		_conn = connection;
		_event = event;
		Connected = true;
	}, Connection)
	return self
end

function Connection:IsConnected()
	if self._conn then
		return self._conn.Connected
	end
	return false
end

function Connection:Disconnect()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	if not self._event then return end
	self.Connected = false
	local connections = self._event._connections
	for i,c in ipairs(connections) do
		if c == self then
			connections[i] = connections[#connections]
			connections[#connections] = nil
			break
		end
	end
	self._event = nil
end

Connection.Destroy = Connection.Disconnect

-- End Connection
-- ------------------------------------------------------------
-- ClientRemoteSignal

--[=[
	@class ClientRemoteSignal
	@client
	Represents a RemoteSignal on the client.
]=]
local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal


--[=[
	@param object any
	@return boolean
	Returns `true` if `object` is a ClientRemoteSignal.
]=]
function ClientRemoteSignal.Is(object)
	return type(object) == "table" and getmetatable(object) == ClientRemoteSignal
end


--[=[
	@param remoteEvent RemoteEvent
	@return ClientRemoteSignal
	Constructs a ClientRemoteSignal which wraps a RemoteEvent instance.
]=]
function ClientRemoteSignal.new(remoteEvent)
	assert(not IS_SERVER, "ClientRemoteSignal can only be created on the client")
	assert(typeof(remoteEvent) == "Instance", "Argument #1 (RemoteEvent) expected Instance; got " .. typeof(remoteEvent))
	assert(remoteEvent:IsA("RemoteEvent"), "Argument #1 (RemoteEvent) expected RemoteEvent; got" .. remoteEvent.ClassName)
	local self = setmetatable({
		_remote = remoteEvent;
		_connections = {};
	}, ClientRemoteSignal)
	return self
end


--[=[
	@param ... any
	Fires the given arguments to the server.
]=]
function ClientRemoteSignal:Fire(...)
	self._remote:FireServer(Ser.SerializeArgsAndUnpack(...))
end


--[=[
	@yields
	@return ...: any
	Waits for the server to fire the signal and returns all the arguments passed.
]=]
function ClientRemoteSignal:Wait()
	return Ser.DeserializeArgsAndUnpack(self._remote.OnClientEvent:Wait())
end


--[=[
	@param handler (...: any) -> nil
	@return Connection
	Connects a function to the signal. The function will be called anytime the
	server fires the signal.
]=]
function ClientRemoteSignal:Connect(handler)
	local connection = Connection.new(self, self._remote.OnClientEvent:Connect(function(...)
		handler(Ser.DeserializeArgsAndUnpack(...))
	end))
	table.insert(self._connections, connection)
	return connection
end


--[=[
	Destroys the ClientRemoteSignal.
]=]
function ClientRemoteSignal:Destroy()
	for _,c in ipairs(self._connections) do
		if c._conn then
			c._conn:Disconnect()
		end
	end
	self._connections = nil
	self._remote = nil
end


return ClientRemoteSignal
