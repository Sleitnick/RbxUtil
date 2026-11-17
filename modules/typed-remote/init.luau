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
export type Event<T... = ()> = Instance & {
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
export type UnreliableEvent<T... = ()> = Event<T...>

--[=[
	@within TypedRemote
	@interface Function<T..., R...>
	.InvokeServer (self: Function<T..., R...>, T...) -> R...,
	.OnServerInvoke (player: Player, T...) -> R...,
]=]
export type Function<T... = (), R... = ()> = Instance & {
	InvokeServer: (self: Function<T..., R...>, T...) -> R...,
	OnServerInvoke: (player: Player, T...) -> R...,
}

type CreatorFn<T> = (name: string) -> T

const IS_SERVER = game:GetService("RunService"):IsServer()

--[=[
	@class TypedRemote

	Simple networking package that helps create typed RemoteEvents and RemoteFunctions.

	```lua
	-- ReplicatedStorage.Network (ModuleScript)

	const TypedRemote = require(ReplicatedStorage.Packages.TypedRemote)

	-- Get the RF, RE and URE instance creators, which create RemoteFunctions/RemoteEvents/UnreliableRemoteEvents
	-- within the given parent (the script by default):
	const RF, RE, URE = TypedRemote.parent()

	-- Define network table:
	return {
		-- RemoteFunction that takes two arguments (boolean, string) and returns a number:
		MyFunc = RF<<(boolean, string), (number)>>("MyFunc"),

		-- RemoteEvent that takes two arguments - a string and a number:
		MyEvent = RE<<(string, number)>>("MyEvent"),

		-- UnreliableRemoteEvent that takes two arguments - a string and a number:
		MyUnreliableEvent = URE<<(string, number)>>("MyUnreliableEvent"),
	}
	```

	```lua
	-- Example usage of the above Network module:

	const Network = require(ReplicatedStorage.Network)

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
const TypedRemote = {}

--[=[
	@return ((name: string) -> RemoteFunction, (name: string) -> RemoteEvent)

	Creates a memoized version of the `func` and `event` functions that include the `parent`
	in each call.

	```lua
	-- Create RF and RE functions that use the current script as the instance parent:
	const RF, RE = TypedRemote.parent(script)

	const remoteFunc = RF("RemoteFunc")
	```
]=]
function TypedRemote.parent(parent: Instance?): (
	<T..., R...>(name: string) -> Function<T..., R...>,
	<T...>(name: string) -> Event<T...>,
	<T...>(name: string) -> UnreliableEvent<T...>
)
	return function<T..., R...>(name: string): Function<T..., R...>
		return TypedRemote.func(name, parent) :: Function<T..., R...>
	end, function<T...>(name: string): Event<T...>
		return TypedRemote.event(name, parent) :: Event<T...>
	end, function<T...>(name: string): UnreliableEvent<T...>
		return TypedRemote.unreliableEvent(name, parent) :: UnreliableEvent<T...>
	end
end

--[=[
	Creates a RemoteFunction with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.func<T..., R...>(name: string, parent: Instance?): Function<T..., R...>
	local rf: RemoteFunction
	if IS_SERVER then
		rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = if parent then parent else script
	else
		rf = ((if parent then parent else script) :: Instance):WaitForChild(name) :: RemoteFunction
		assert(rf:IsA("RemoteFunction"), "expected remote function")
	end
	return rf :: Function<T..., R...>
end

--[=[
	Creates a RemoteEvent with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.event<T...>(name: string, parent: Instance?): Event<T...>
	local re: RemoteEvent
	if IS_SERVER then
		re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = if parent then parent else script
	else
		re = ((if parent then parent else script) :: Instance):WaitForChild(name) :: RemoteEvent
		assert(re:IsA("RemoteEvent"), "expected remote event")
	end
	return re :: Event<T...>
end

--[=[
	Creates an UnreliableRemoteEvent with `name` and parents it inside of `parent`.
	
	If the `parent` argument is not included or is `nil`, then it defaults to the parent of
	this TypedRemote ModuleScript.
]=]
function TypedRemote.unreliableEvent<T...>(name: string, parent: Instance?): UnreliableEvent<T...>
	local ure: UnreliableRemoteEvent
	if IS_SERVER then
		ure = Instance.new("UnreliableRemoteEvent")
		ure.Name = name
		ure.Parent = if parent then parent else script
	else
		ure = ((if parent then parent else script) :: Instance):WaitForChild(name) :: UnreliableRemoteEvent
		assert(ure:IsA("UnreliableRemoteEvent"), "expected unreliable remote event")
	end
	return ure :: UnreliableEvent<T...>
end

table.freeze(TypedRemote)

return TypedRemote
