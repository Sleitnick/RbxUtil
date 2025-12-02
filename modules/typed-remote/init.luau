--!strict

type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	ConnectParallel: (self: Signal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> RBXScriptConnection,
	Wait: (self: Signal<T...>) -> T...,
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
	.OnClientEvent Signal<T...>,
	.OnServerEvent PlayerSignal<T...>,
	.FireClient (self: Event<T...>, player: Player, T...) -> (),
	.FireAllClients (self: Event<T...>, T...) -> (),
	.FireServer (self: Event<T...>, T...) -> (),
]=]
export type Event<T...> = {
	OnClientEvent: Signal<T...>,
	OnServerEvent: PlayerSignal<T...>,
	FireClient: (self: Event<T...>, player: Player, T...) -> (),
	FireAllClients: (self: Event<T...>, T...) -> (),
	FireServer: (self: Event<T...>, T...) -> (),
}

--[=[
	@within TypedRemote
	@interface UnreliableEvent<T...>
	.OnClientEvent Signal<T...>,
	.OnServerEvent PlayerSignal<T...>,
	.FireClient (self: Event<T...>, player: Player, T...) -> (),
	.FireAllClients (self: Event<T...>, T...) -> (),
	.FireServer (self: Event<T...>, T...) -> (),
]=]
export type UnreliableEvent<T...> = Event<T...>

type function FnInjectFirstArg(first: type, fnOriginal: type)
	if fnOriginal.tag ~= "function" then
		print(`expected function type; got {fnOriginal.tag}`)
		return types.never
	end

	local params: { type } = {}
	local paramsTail: type? = nil

	table.insert(params, first)

	local fnOriginalParams = fnOriginal:parameters()
	if fnOriginalParams.head then
		for _, param in fnOriginalParams.head do
			table.insert(params, param)
		end
	end
	paramsTail = fnOriginalParams.tail

	local returns = fnOriginal:returns()

	local fn = types.newfunction({ head = params, tail = paramsTail }, returns)

	return fn
end

--[=[
	@within TypedRemote
	@interface Function<Fn>
	.InvokeServer (self: Function, FnParams) -> FnReturns,
	.OnServerInvoke (player: Player, FnParams) -> FnReturns,

	```lua
	-- A Function type that takes a number and a string and returns a boolean and CFrame
	type Fn = Function<(number, string) -> (boolean, CFrame)>
	```
]=]
export type Function<Fn> = {
	InvokeServer: FnInjectFirstArg<any, Fn>,
	OnServerInvoke: FnInjectFirstArg<Player, Fn>,
}

type CreatorFn<T> = (name: string) -> T

local IS_SERVER = game:GetService("RunService"):IsServer()

--[=[
	@class TypedRemote

	Simple networking package that helps create typed RemoteEvents and RemoteFunctions.

	```lua
	-- ReplicatedStorage.Network (ModuleScript)

	local TypedRemote = require(ReplicatedStorage.Packages.TypedRemote)

	-- Get the RF, RE and URE instance creators, which create RemoteFunctions/RemoteEvents/UnreliableRemoteEvents
	-- within the given parent (the script by default):
	local RF, RE, URE = TypedRemote.parent()

	-- Redeclare the TypedRemote types for simplicity:
	type RF<Fn> = TypedRemote.Function<Fn>
	type RE<Args...> = TypedRemote.Event<Args...>
	type URE<Args...> = TypedRemote.UnreliableEvent<Args...>

	-- Define network table:
	return {
		-- RemoteFunction that takes two arguments (boolean, string) and returns a number:
		MyFunc = RF("MyFunc") :: RF<(boolean, string) -> number>,

		-- RemoteEvent that takes two arguments - a string and a number:
		MyEvent = RE("MyEvent") :: RE<string, number>,

		-- UnreliableRemoteEvent that takes two arguments - a string and a number:
		MyUnreliableEvent = URE("MyUnreliableEvent") :: URE<string, number>,
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
	@return ((name: string) -> RemoteFunction, (name: string) -> RemoteEvent, (name: string) -> UnreliableRemoteEvent)

	Creates a memoized version of the `func` and `event` functions that include the `parent`
	in each call.

	```lua
	-- Create RF, RE, and URE functions that use the current script as the instance parent:
	local RF, RE, URE = TypedRemote.parent(script)

	local remoteFunc = RF("RemoteFunc")
	```
]=]
function TypedRemote.parent(
	parent: Instance?
): (CreatorFn<RemoteFunction>, CreatorFn<RemoteEvent>, CreatorFn<UnreliableRemoteEvent>)
	return function(name: string)
		return TypedRemote.func(name, parent)
	end, function(name: string)
		return TypedRemote.event(name, parent)
	end, function(name: string)
		return TypedRemote.unreliableEvent(name, parent)
	end
end

--[=[
	Creates a RemoteFunction with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.func(name: string, parent: Instance?): RemoteFunction
	local rf: RemoteFunction
	if IS_SERVER then
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = if parent then parent else script
	else
		rf = (if parent then parent else script :: Instance):WaitForChild(name) :: RemoteFunction
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
		re = (if parent then parent else script :: Instance):WaitForChild(name) :: RemoteEvent
		assert(re:IsA("RemoteEvent"), "expected remote event")
	end
	return re
end

--[=[
	Creates an UnreliableRemoteEvent with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.unreliableEvent(name: string, parent: Instance?): UnreliableRemoteEvent
	local ure: UnreliableRemoteEvent
	if IS_SERVER then
		ure = Instance.new("UnreliableRemoteEvent")
		ure.Name = name
		ure.Parent = if parent then parent else script
	else
		ure = (if parent then parent else script :: Instance):WaitForChild(name) :: UnreliableRemoteEvent
		assert(ure:IsA("UnreliableRemoteEvent"), "expected unreliable remote event")
	end
	return ure
end

return table.freeze(TypedRemote)
