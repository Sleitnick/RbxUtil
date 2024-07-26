--!strict

type Signal<T...> = {
	Connect: (self: PlayerSignal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	ConnectParallel: (self: PlayerSignal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	Once: (self: PlayerSignal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	Wait: (self: PlayerSignal<T...>) -> T...,
}

type PlayerSignal<T...> = {
	Connect: (self: PlayerSignal<T...>, fn: (player: Player, T...) -> ()) -> RBXScriptConnection,
	ConnectParallel: (self: PlayerSignal<T...>, fn: (player: Player, T...) -> ()) -> RBXScriptConnection,
	Once: (self: PlayerSignal<T...>, fn: (player: Player, T...) -> ()) -> RBXScriptConnection,
	Wait: (self: PlayerSignal<T...>) -> (Player, T...),
}

--[=[
	@within TypedRemote
	@interface Event<T...>
	.OnClientEvent PlayerSignal<T...>,
	.OnServerEvent Signal<T...>,
	.FireClient (self: Event<T...>, player: Player, T...) -> (),
	.FireAllClients (self: Event<T...>, T...) -> (),
	.FireServer (self: Event<T...>, T...) -> (),
]=]
export type Event<T...> = Instance & {
	OnClientEvent: PlayerSignal<T...>,
	OnServerEvent: Signal<T...>,
	FireClient: (self: Event<T...>, player: Player, T...) -> (),
	FireAllClients: (self: Event<T...>, T...) -> (),
	FireServer: (self: Event<T...>, T...) -> (),
}

--[=[
	@within TypedRemote
	@interface Function<T..., R...>
	.InvokeServer (self: Function<T..., R...>, T...) -> R...,
	.OnServerInvoke (player: Player, T...) -> R...,
]=]
export type Function<T..., R...> = Instance & {
	InvokeServer: (self: Function<T..., R...>, T...) -> R...,
	OnServerInvoke: (player: Player, T...) -> R...,
}

local IS_SERVER = game:GetService("RunService"):IsServer()

--[=[
	@class TypedRemote

	Simple networking package that helps create typed RemoteEvents and RemoteFunctions.

	```lua
	-- ReplicatedStorage.Network (ModuleScript)

	local TypedRemote = require(ReplicatedStorage.Packages.TypedRemote)

	-- Get the RF and RE instance creators, which create RemoteEvents/RemoteFunctions
	-- within the given parent (the script in this case):
	local RF, RE = TypedRemote.parent(script)

	-- Redeclare the TypedRemote types for simplicity:
	type RF<T..., R...> = TypedRemote.Function<T..., R...>
	type RE<T...> = TypedRemote.Event<T...>

	-- Define network table:
	return {
		-- RemoteEvent that takes two arguments - a string and a number:
		MyEvent = RE("MyEvent") :: RE<string, number>,

		-- RemoteFunction that takes two arguments (boolean, string) and returns a number:
		MyFunc = RF("MyFunc") :: RF<(boolean, string), (number)>,
	}
	```

	```lua
	-- Example usage of the above Network module:

	local Network = require(ReplicatedStorage.Network)

	-- If you type this out, intellisense will help with what the function signature should be:
	Network.MyEvent.OnClientEvent:Connect(function(player, str, num)
		-- Foo
	end)
	```

	In most cases, the `TypedRemote.parent()` function will be used to create the memoized
	RemoteFunction and RemoteEvent builder functions. From there, call the given functions
	with the desired name per remote.

	The `TypedRemote.func` and `TypedRemote.event` functions can also be used, but the
	parent must be supplied to each call, hence the helpful `parent()` memoizer.
]=]
local TypedRemote = {}

--[=[
	@return ((name: string) -> RemoteFunction, (name: string) -> RemoteEvent)

	Creates a memoized version of the `func` and `event` functions that include the `parent`
	in each call.

	```lua
	-- Create RF and RE functions that use the current script as the instance parent:
	local RF, RE = TypedRemote.parent(script)

	local remoteFunc = RF("RemoteFunc")
	```
]=]
function TypedRemote.parent(parent: Instance)
	return function(name: string)
		return TypedRemote.func(name, parent)
	end, function(name: string)
		return TypedRemote.event(name, parent)
	end
end

--[=[
	Creates a RemoteFunction with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.func(name: string, parent: Instance): RemoteFunction
	local rf: RemoteFunction
	if IS_SERVER then
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = if parent then parent else script
	else
		rf = (if parent then parent else script):WaitForChild(name)
		assert(rf:IsA("RemoteFunction"), "expected remote function")
	end
	return rf
end

--[=[
	Creates a RemoteEvent with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.event(name: string, parent: Instance?): RemoteEvent
	local re: RemoteEvent
	if IS_SERVER then
		re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = if parent then parent else script
	else
		re = (if parent then parent else script):WaitForChild(name)
		assert(re:IsA("RemoteEvent"), "expected remote event")
	end
	return re
end

table.freeze(TypedRemote)

return TypedRemote
