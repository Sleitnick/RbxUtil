local RunService = game:GetService("RunService")

--[=[
	@class Net
	Basic networking module for creating and handling static
	RemoteEvents and RemoteFunctions.
]=]
local Net = {}

--[=[
	Gets a RemoteEvent with the given name.

	On the server, if the RemoteEvent does not exist, then
	it will be created with the given name.

	On the client, if the RemoteEvent does not exist, then
	it will wait until it exists for at least 10 seconds.
	If the RemoteEvent does not exist after 10 seconds, an
	error will be thrown.

	```lua
	local remoteEvent = Net:RemoteEvent("PointsChanged")
	```
]=]
function Net:RemoteEvent(name: string): RemoteEvent
	name = "RE/" .. name
	if RunService:IsServer() then
		local r = script:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = script
		end
		return r
	else
		local r = script:WaitForChild(name, 10)
		if not r then
			error("Failed to find RemoteEvent: " .. name, 2)
		end
		return r
	end
end

--[=[
	Gets an UnreliableRemoteEvent with the given name.

	On the server, if the UnreliableRemoteEvent does not
	exist, then it will be created with the given name.

	On the client, if the UnreliableRemoteEvent does not
	exist, then it will wait until it exists for at least
	10 seconds. If the UnreliableRemoteEvent does not exist
	after 10 seconds, an error will be thrown.

	```lua
	local unreliableRemoteEvent = Net:UnreliableRemoteEvent("PositionChanged")
	```
]=]
function Net:UnreliableRemoteEvent(name: string): UnreliableRemoteEvent
	name = "URE/" .. name
	if RunService:IsServer() then
		local r = script:FindFirstChild(name)
		if not r then
			r = Instance.new("UnreliableRemoteEvent")
			r.Name = name
			r.Parent = script
		end
		return r
	else
		local r = script:WaitForChild(name, 10)
		if not r then
			error("Failed to find UnreliableRemoteEvent: " .. name, 2)
		end
		return r
	end
end

--[=[
	Connects a handler function to the given RemoteEvent.

	```lua
	-- Client
	Net:Connect("PointsChanged", function(points)
		print("Points", points)
	end)

	-- Server
	Net:Connect("SomeEvent", function(player, ...) end)
	```
]=]
function Net:Connect(name: string, handler: (...any) -> ()): RBXScriptConnection
	if RunService:IsServer() then
		return self:RemoteEvent(name).OnServerEvent:Connect(handler)
	else
		return self:RemoteEvent(name).OnClientEvent:Connect(handler)
	end
end

--[=[
	Connects a handler function to the given UnreliableRemoteEvent.

	```lua
	-- Client
	Net:ConnectUnreliable("PositionChanged", function(position)
		print("Position", position)
	end)

	-- Server
	Net:ConnectUnreliable("SomeEvent", function(player, ...) end)
	```
]=]
function Net:ConnectUnreliable(name: string, handler: (...any) -> ()): RBXScriptConnection
	if RunService:IsServer() then
		return self:UnreliableRemoteEvent(name).OnServerEvent:Connect(handler)
	else
		return self:UnreliableRemoteEvent(name).OnClientEvent:Connect(handler)
	end
end

--[=[
	Gets a RemoteFunction with the given name.

	On the server, if the RemoteFunction does not exist, then
	it will be created with the given name.

	On the client, if the RemoteFunction does not exist, then
	it will wait until it exists for at least 10 seconds.
	If the RemoteFunction does not exist after 10 seconds, an
	error will be thrown.

	```lua
	local remoteFunction = Net:RemoteFunction("GetPoints")
	```
]=]
function Net:RemoteFunction(name: string): RemoteFunction
	name = "RF/" .. name
	if RunService:IsServer() then
		local r = script:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = script
		end
		return r
	else
		local r = script:WaitForChild(name, 10)
		if not r then
			error("Failed to find RemoteFunction: " .. name, 2)
		end
		return r
	end
end

--[=[
	@server
	Sets the invocation function for the given RemoteFunction.

	```lua
	Net:Handle("GetPoints", function(player)
		return 10
	end)
	```
]=]
function Net:Handle(name: string, handler: (player: Player, ...any) -> ...any)
	self:RemoteFunction(name).OnServerInvoke = handler
end

--[=[
	@client
	Invokes the RemoteFunction with the given arguments.

	```lua
	local points = Net:Invoke("GetPoints")
	```
]=]
function Net:Invoke(name: string, ...: any): ...any
	return self:RemoteFunction(name):InvokeServer(...)
end

--[=[
	@server
	Destroys all RemoteEvents and RemoteFunctions. This
	should really only be used in testing environments
	and not during runtime.
]=]
function Net:Clean()
	script:ClearAllChildren()
end

return Net
