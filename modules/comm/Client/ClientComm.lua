-- ClientComm
-- Stephen Leitnick
-- December 20, 2021

local Comm = require(script.Parent)
local Util = require(script.Parent.Parent.Util)
local Types = require(script.Parent.Parent.Types)

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

	```lua
	local clientComm = ClientComm.new(game:GetService("ReplicatedStorage"), true)

	-- If using a unique namespace with ServerComm, include it as second argument:
	local clientComm = ClientComm.new(game:GetService("ReplicatedStorage"), true, "MyNamespace")
	```
]=]
function ClientComm.new(parent: Instance, usePromise: boolean, namespace: string?)
	assert(not Util.IsServer, "ClientComm must be constructed from the client")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = Util.DefaultCommFolderName
	if namespace then
		ns = namespace
	end
	local folder: Instance? = parent:WaitForChild(ns, Util.WaitForChildTimeout)
	assert(folder ~= nil, "Could not find namespace for ClientComm in parent: " .. ns)
	local self = setmetatable({}, ClientComm)
	self._instancesFolder = folder
	self._usePromise = usePromise
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
function ClientComm:GetFunction(name: string, inboundMiddleware: Types.ClientMiddleware?, outboundMiddleware: Types.ClientMiddleware?)
	return Comm.GetFunction(self._instancesFolder, name, self._usePromise, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param inboundMiddleware ClientMiddleware?
	@param outboundMiddleware ClientMiddleware?
	@return ClientRemoteSignal
	Returns a new ClientRemoteSignal that mirrors the matching RemoteSignal created by
	ServerComm with the same matching `name`.

	```lua
	local mySignal = clientComm:GetSignal("MySignal")

	-- Listen for data from the server:
	mySignal:Connect(function(message)
		print("Received message from server:", message)
	end)

	-- Send data to the server:
	mySignal:Fire("Hello!")
	```
]=]
function ClientComm:GetSignal(name: string, inboundMiddleware: Types.ClientMiddleware?, outboundMiddleware: Types.ClientMiddleware?)
	return Comm.GetSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end

--[=[
	@param name string
	@param inboundMiddleware ClientMiddleware?
	@param outboundMiddleware ClientMiddleware?
	@return ClientRemoteProperty
	Returns a new ClientRemoteProperty that mirrors the matching RemoteProperty created by
	ServerComm with the same matching `name`.

	Take a look at the ClientRemoteProperty documentation for more info, such as
	understanding how to wait for data to be ready.

	```lua
	local mapInfo = clientComm:GetProperty("MapInfo")

	-- Observe the initial value of mapInfo, and all subsequent changes:
	mapInfo:Observe(function(info)
		print("Current map info", info)
	end)

	-- Check to see if data is initially ready:
	if mapInfo:IsReady() then
		-- Get the data:
		local info = mapInfo:Get()
	end

	-- Get a promise that resolves once the data is ready (resolves immediately if already ready):
	mapInfo:OnReady():andThen(function(info)
		print("Map info is ready with info", info)
	end)

	-- Same as above, but yields thread:
	local success, info = mapInfo:OnReady():await()
	```
]=]
function ClientComm:GetProperty(name: string, inboundMiddleware: Types.ClientMiddleware?, outboundMiddleware: Types.ClientMiddleware?)
	return Comm.GetProperty(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
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
	serverComm:CreateProperty("MyProperty", 10)

	-- Client-side
	local obj = clientComm:BuildObject()
	obj:Test()
	obj.MySignal:Connect(function(data) end)
	obj.MyProperty:Observe(function(value) end)
	```
]=]
function ClientComm:BuildObject(inboundMiddleware: Types.ClientMiddleware?, outboundMiddleware: Types.ClientMiddleware?)
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

return ClientComm
