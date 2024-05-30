local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[=[
	@class Net
	Basic networking module for creating and handling static
	RemoteEvents and RemoteFunctions.
]=]
local Net = {}

--[=[
    Gets the folder that contains all of Net's managed RemoteEvents and RemoteFunctions.

    On the server, the folder will be created if it does not exist, and then returned

    On the client, if the folder does not exist, then it will wait until it exists for 10 seconds.
]=]
local function getNetFolder(): Folder
    if RunService:IsServer() then
        local netFolder = ReplicatedStorage:FindFirstChild("Net")
        if not netFolder then
            local newNetFolder = Instance.new("Folder")
            newNetFolder.Name = "Net"
            newNetFolder.Parent = ReplicatedStorage
            netFolder = newNetFolder
        end
        return netFolder :: Folder
    else
        local netFolder = ReplicatedStorage:WaitForChild("Net", 10)
        if not netFolder then
            error("Failed to find Net folder", 2)
        end
        return netFolder :: Folder
    end
end

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
    local netFolder = getNetFolder()
    
	if RunService:IsServer() then
		local r = netFolder:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = netFolder
		end
		return r
	else
		local r = netFolder:WaitForChild(name, 10)
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
    local netFolder = getNetFolder()
	if RunService:IsServer() then
		local r = netFolder:FindFirstChild(name)
		if not r then
			r = Instance.new("UnreliableRemoteEvent")
			r.Name = name
			r.Parent = netFolder
		end
		return r
	else
		local r = netFolder:WaitForChild(name, 10)
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
    local netFolder = getNetFolder()
	if RunService:IsServer() then
		local r = netFolder:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = netFolder
		end
		return r
	else
		local r = netFolder:WaitForChild(name, 10)
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
	getNetFolder():ClearAllChildren()
end

return Net
