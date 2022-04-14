-- ClientRemoteSignal
-- Stephen Leitnick
-- December 20, 2021


local Signal = require(script.Parent.Parent.Parent.Signal)
local Types = require(script.Parent.Parent.Types)

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
	.Disconnect () -> ()
]=]

function ClientRemoteSignal.new(re: RemoteEvent, inboundMiddleware: Types.ClientMiddleware?, outboudMiddleware: Types.ClientMiddleware?)
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
		self._signal = Signal.new()
		self._reConn = self._re.OnClientEvent:Connect(function(...)
			local args = table.pack(...)
			for _,middlewareFunc in ipairs(inboundMiddleware) do
				local middlewareResult = table.pack(middlewareFunc(args))
				if not middlewareResult[1] then
					return
				end
				args.n = #args
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
		args.n = #args
	end
	return table.unpack(args, 1, args.n)
end

--[=[
	@param fn (...: any) -> ()
	@return Connection
	Connects a function to the remote signal. The function will be
	called anytime the equivalent server-side RemoteSignal is
	fired at this specific client that created this client signal.
]=]
function ClientRemoteSignal:Connect(fn: (...any) -> ())
	if self._directConnect then
		return self._re.OnClientEvent:Connect(fn)
	else
		return self._signal:Connect(fn)
	end
end

--[=[
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

return ClientRemoteSignal
