local Util = require(script.Parent.Util)
local Types = require(script.Parent.Types)
local Promise = require(script.Parent.Parent.Promise)
local ClientRemoteSignal = require(script.ClientRemoteSignal)
local ClientRemoteProperty = require(script.ClientRemoteProperty)

local Client = {}

function Client.GetFunction(
	parent: Instance,
	name: string,
	usePromise: boolean,
	inboundMiddleware: Types.ClientMiddleware?,
	outboundMiddleware: Types.ClientMiddleware?
)
	assert(not Util.IsServer, "GetFunction must be called from the client")
	local folder = Util.GetCommSubFolder(parent, "RF"):Expect("Failed to get Comm RF folder")
	local rf = folder:WaitForChild(name, Util.WaitForChildTimeout)
	assert(rf ~= nil, "Failed to find RemoteFunction: " .. name)
	local hasInbound = type(inboundMiddleware) == "table" and #inboundMiddleware > 0
	local hasOutbound = type(outboundMiddleware) == "table" and #outboundMiddleware > 0
	local function ProcessOutbound(args)
		for _, middlewareFunc in ipairs(outboundMiddleware) do
			local middlewareResult = table.pack(middlewareFunc(args))
			if not middlewareResult[1] then
				return table.unpack(middlewareResult, 2, middlewareResult.n)
			end
			args.n = #args
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
						for _, middlewareFunc in ipairs(inboundMiddleware) do
							local middlewareResult = table.pack(middlewareFunc(res))
							if not middlewareResult[1] then
								return table.unpack(middlewareResult, 2, middlewareResult.n)
							end
							res.n = #res
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
				for _, middlewareFunc in ipairs(inboundMiddleware) do
					local middlewareResult = table.pack(middlewareFunc(res))
					if not middlewareResult[1] then
						return table.unpack(middlewareResult, 2, middlewareResult.n)
					end
					res.n = #res
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

function Client.GetSignal(
	parent: Instance,
	name: string,
	inboundMiddleware: Types.ClientMiddleware?,
	outboundMiddleware: Types.ClientMiddleware?
)
	assert(not Util.IsServer, "GetSignal must be called from the client")
	local folder = Util.GetCommSubFolder(parent, "RE"):Expect("Failed to get Comm RE folder")
	local re = folder:WaitForChild(name, Util.WaitForChildTimeout)
	assert(re ~= nil, "Failed to find RemoteEvent: " .. name)
	return ClientRemoteSignal.new(re, inboundMiddleware, outboundMiddleware)
end

function Client.GetProperty(
	parent: Instance,
	name: string,
	inboundMiddleware: Types.ClientMiddleware?,
	outboundMiddleware: Types.ClientMiddleware?
)
	assert(not Util.IsServer, "GetProperty must be called from the client")
	local folder = Util.GetCommSubFolder(parent, "RP"):Expect("Failed to get Comm RP folder")
	local re = folder:WaitForChild(name, Util.WaitForChildTimeout)
	assert(re ~= nil, "Failed to find RemoteEvent for RemoteProperty: " .. name)
	return ClientRemoteProperty.new(re, inboundMiddleware, outboundMiddleware)
end

return Client
