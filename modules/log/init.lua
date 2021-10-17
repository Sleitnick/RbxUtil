-- Log
-- Stephen Leitnick
-- April 20, 2021

--[[

	IMPORTANT: Only make one logger per script/module


	Log.Level { Trace, Debug, Info, Warning, Error, Fatal }
	Log.TimeUnit { Milliseconds, Seconds, Minutes, Hours, Days, Weeks, Months, Years }

	Constructor:

		logger = Log.new()


	Log:

		Basic logging at levels:

			logger:AtTrace():Log("Hello from trace")
			logger:AtDebug():Log("Hello from debug")
			logger:AtInfo():Log("Hello from info")
			logger:AtWarning():Log("Hello from warn")
			logger:AtError():Log("Hello from error")
			logger:AtFatal():Log("Hello from fatal")
			logger:At(Log.Level.Warning):Log("Warning!")


		Log every 10 logs:

			logger:AtInfo():Every(10):Log("Log this only every 10 times")


		Log at most every 3 seconds:

			logger:AtInfo():AtMostEvery(3, Log.TimeUnit.Seconds):Log("Hello there, but not too often!")


		Wrap the Log in a function:

			local log = logger:AtDebug():Wrap()
			log("Hello")


	--------------------------------------------------------------------------------------------------------------

	LogConfig: Create a LogConfig ModuleScript anywhere in ReplicatedStorage. The configuration lets developers
	tune the lowest logging level based on various environment conditions. The LogConfig will be automatically
	required and used to set the log level.

	To set the default configuration for all environments, simply return the log level from the LogConfig:

		return "Info"

	To set a configuration that is different while in Studio:

		return {
			Studio = "Debug";
			Other = "Warn"; -- "Other" can be anything other than Studio (e.g. could be named "Default")
		}

	Fine-tune between server and client:

		return {
			Studio = {
				Server = "Info";
				Client = "Debug";
			};
			Other = "Warn";
		}

	Fine-tune based on PlaceIds:

		return {
			Studio = {
				Server = "Info";
				Client = "Debug";
			};
			Other = {
				PlaceIds = {123456, 234567}
				Server = "Severe";
				Client = "Warn";
			};
		}

	Fine-tune based on GameIds:

		return {
			Studio = {
				Server = "Info";
				Client = "Debug";
			};
			Other = {
				GameIds = {123456, 234567}
				Server = "Severe";
				Client = "Warn";
			};
		}

	Example of full-scale config with multiple environments:

		return {
			Studio = {
				Server = "Debug";
				Client = "Debug";
			};
			Dev = {
				PlaceIds = {1234567};
				Server = "Info";
				Client = "Info";
			};
			Prod = {
				PlaceIds = {2345678};
				Server = "Severe";
				Client = "Warn";
			};
			Default = "Info";
		}

--]]


local IS_STUDIO = game:GetService("RunService"):IsStudio()
local IS_SERVER = game:GetService("RunService"):IsServer()

local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")
local AnalyticsLogLevel = Enum.AnalyticsLogLevel
local Players = game:GetService("Players")

local player = ((not IS_SERVER) and Players.LocalPlayer or nil)

local configModule = game:GetService("ReplicatedStorage"):FindFirstChild("LogConfig", true)
local config = (configModule and require(configModule) or "Debug")

local logLevel = nil
local timeFunc = os.clock

local logLevels = {
	Trace = AnalyticsLogLevel.Trace.Value;
	Debug = AnalyticsLogLevel.Debug.Value;
	Info = AnalyticsLogLevel.Information.Value;
	Warning = AnalyticsLogLevel.Warning.Value;
	Error = AnalyticsLogLevel.Error.Value;
	Fatal = AnalyticsLogLevel.Fatal.Value;
}

local timeUnits = {
	Milliseconds = 0;
	Seconds = 1;
	Minutes = 2;
	Hours = 3;
	Days = 4;
	Weeks = 5;
	Months = 6;
	Years = 7;
}

local function ToSeconds(n, timeUnit)
	if timeUnit == timeUnits.Milliseconds then
		return n / 1000
	elseif timeUnit == timeUnits.Seconds then
		return n
	elseif timeUnit == timeUnits.Minutes then
		return n * 60
	elseif timeUnit == timeUnits.Hours then
		return n * 3600
	elseif timeUnit == timeUnits.Days then
		return n * 86400
	elseif timeUnit == timeUnits.Weeks then
		return n * 604800
	elseif timeUnit == timeUnits.Months then
		return n * 2592000
	elseif timeUnit == timeUnits.Years then
		return n * 31536000
	else
		error("Unknown time unit", 2)
	end
end


local function GetPlayerFromCustomData(customData)
	if type(customData) == "table" then
		local id = (customData.Player or customData.PlayerId)
		if id then
			return Players:GetPlayerByUserId(id)
		end
	end
	return nil
end


local FireAnalyticsLogEvent
if IS_STUDIO then
	FireAnalyticsLogEvent = function(_level, _message, _traceback, _customData) end
else
	FireAnalyticsLogEvent = function(level, message, traceback, customData)
		local success, err = pcall(function()
			local plr = (player or GetPlayerFromCustomData(customData))
			AnalyticsService:FireLogEvent(plr, level, message, {stackTrace = traceback}, customData)
		end)
		if not success then
			warn(err)
		end
	end
end


local LogItem = {}
LogItem.__index = LogItem

function LogItem.new(log, levelName, traceback, key)
	local self = setmetatable({
		_log = log;
		_traceback = traceback;
		_levelName = levelName;
		_modifiers = {
			Throw = false;
		};
		_key = key;
	}, LogItem)
	return self
end

function LogItem:_shouldLog(stats)
	if self._modifiers.Every and not stats:_checkAndIncrementCount(self._modifiers.Every) then
		return false
	end
	if self._modifiers.AtMostEvery and not stats:_checkLastTimestamp(timeFunc(), self._modifiers.AtMostEvery) then
		return false
	end
	return true
end

function LogItem:Every(n)
	self._modifiers.Every = n
	return self
end

function LogItem:AtMostEvery(n, timeUnit)
	self._modifiers.AtMostEvery = ToSeconds(n, timeUnit)
	return self
end

function LogItem:Throw()
	self._modifiers.Throw = true
	return self
end

function LogItem:Log(message, customData)
	local stats = self._log:_getLogStats(self._key)
	if not self:_shouldLog(stats) then return end
	if type(message) == "function" then
		local msg, data = message()
		message = msg
		if data ~= nil then
			customData = data
		end
	elseif type(message) == "table" then
		message = HttpService:JSONEncode(message)
	end
	stats:_setTimestamp(timeFunc())
	local logMessage = ("%s: [%s] %s"):format(self._log._name, self._levelName, message)
	local logLevelNum = logLevels[self._levelName]
	FireAnalyticsLogEvent(logLevelNum, ("%s: %s"):format(self._log._name, message), self._traceback, customData)
	if self._modifiers.Throw then
		error(logMessage .. (customData and (" " .. HttpService:JSONEncode(customData)) or ""), 4)
	elseif logLevelNum < logLevels.Warning then
		print(logMessage, customData or "")
	else
		warn(logMessage, customData or "")
	end
end

function LogItem:Wrap()
	return function(...)
		self:Log(...)
	end
end

function LogItem:Assert(condition, ...)
	if condition then
		self:Throw():Log(...)
	end
end


local LogItemBlank = {}
LogItemBlank.__index = LogItemBlank
setmetatable(LogItemBlank, LogItem)

function LogItemBlank.new(...)
	local self = setmetatable(LogItem.new(...), LogItemBlank)
	return self
end

function LogItemBlank:Log()
	-- Do nothing
end


local LogStats = {}
LogStats.__index = LogStats

function LogStats.new()
	local self = setmetatable({}, LogStats)
	self._invocationCount = 0
	self._lastTimestamp = 0
	return self
end

function LogStats:_checkAndIncrementCount(rateLimit)
	local check = ((self._invocationCount % rateLimit) == 0)
	self._invocationCount += 1
	return check
end

function LogStats:_checkLastTimestamp(now, intervalSeconds)
	return ((now - self._lastTimestamp) >= intervalSeconds)
end

function LogStats:_setTimestamp(now)
	self._lastTimestamp = now
end


--[=[
	@class Log
	@server
	Log class for logging to the AnalyticsService (e.g. PlayFab). The API
	is based off of Google's [Flogger](https://google.github.io/flogger/)
	fluent logging API.

	```lua
	local Log = require(somewhere.Log)
	local logger = Log.new()

	-- Log a simple message:
	logger:AtInfo():Log("Hello world!")

	-- Log only every 3 messages:
	for i = 1,20 do
		logger:AtInfo():Every(3):Log("Hi there!")
	end

	-- Log only every 1 second:
	for i = 1,100 do
		logger:AtInfo():AtMostEvery(3, Log.TimeUnit.Seconds):Log("Hello!")
		task.wait(0.1)
	end

	-- Wrap the above example into a function:
	local log = logger:AtInfo():AtMostEvery(3, Log.TimeUnit.Seconds):Wrap()
	for i = 1,100 do
		log("Hello!")
		task.wait(0.1)
	end

	-- Assertion:
	logger:Assert(typeof(32) == "number", "Somehow 32 is no longer a number")
	```

	------------

	### LogConfig

	A LogConfig ModuleScript is expected to exist somewhere within ReplicatedStorage
	as well. This ModuleScript defines the behavior for the logger. If not found,
	the logger will default to the Debug log level for all operations.

	For instance, this could be a script located at `ReplicatedStorage.MyGameConfig.LogConfig`. There
	just needs to be some `LogConfig`-named ModuleScript within ReplicatedStorage.

	Below are a few examples of possible LogConfig ModuleScripts:

	```lua
	-- Set "Info" as default log level for all environments:
	return "Info"
	```

	```lua
	-- To set a configuration that is different while in Studio:
	return {
		Studio = "Debug";
		Other = "Warn"; -- "Other" can be anything other than Studio (e.g. could be named "Default")
	}
	```

	```lua
	-- Fine-tune between server and client:
	return {
		Studio = {
			Server = "Info";
			Client = "Debug";
		};
		Other = "Warn";
	}
	```

	```lua
	-- Fine-tune based on PlaceIds:
	return {
		Studio = {
			Server = "Info";
			Client = "Debug";
		};
		Other = {
			PlaceIds = {123456, 234567}
			Server = "Severe";
			Client = "Warn";
		};
	}
	```

	```lua
	-- Fine-tune based on GameIds:
	return {
		Studio = {
			Server = "Info";
			Client = "Debug";
		};
		Other = {
			GameIds = {123456, 234567}
			Server = "Severe";
			Client = "Warn";
		};
	}
	```

	```lua
	-- Example of full-scale config with multiple environments:
	return {
		Studio = {
			Server = "Debug";
			Client = "Debug";
		};
		Dev = {
			PlaceIds = {1234567};
			Server = "Info";
			Client = "Info";
		};
		Prod = {
			PlaceIds = {2345678};
			Server = "Severe";
			Client = "Warn";
		};
		Default = "Info";
	}
	```
]=]
local Log = {}
Log.__index = Log

--[=[
	@within Log
	@interface LogItem
	.Log (message: any, customData: table?) -- Log the message
	.Every (n: number) -- Log only every `n` times
	.AtMostEvery (n: number, timeUnit: TimeUnit) -- Log only every `n` `TimeUnit`
	.Throw () -- Throw an error
	.Wrap () -- Returns a function that can be called which will log out the given arguments
	.Assert (condition: boolean, args: ...) -- Assert the condition
]=]

--[=[
	@within Log
	@interface TimeUnit
	.Milliseconds number
	.Seeconds number
	.Minutes number
	.Hours number
	.Days number
	.Weeks number
	.Months number
	.Years number
]=]

--[=[
	@within Log
	@interface Level
	.Trace number
	.Debug number
	.Info number
	.Warning number
	.Error number
	.Fatal number
]=]

--[=[
	@within Log
	@prop TimeUnit TimeUnit
	@readonly
]=]

--[=[
	@within Log
	@prop Level Level
	@readonly
]=]


Log.TimeUnit = timeUnits
Log.Level = logLevels

Log.LevelNames = {}
for name,num in pairs(Log.Level) do
	Log.LevelNames[num] = name
end


--[=[
	@return Log
	Construct a new Log object.

	:::warning
	This should only be called once per script.
	:::
]=]
function Log.new()
	local self = setmetatable({}, Log)
	local name = debug.info(2, "s"):match("([^%.]-)$")
	self._name = name
	self._stats = {}
	return self
end


function Log:_getLogStats(key)
	local stats = self._stats[key]
	if not stats then
		stats = LogStats.new()
		self._stats[key] = stats
	end
	return stats
end


function Log:_at(level)
	local l, f = debug.info(3, "lf")
	local traceback = debug.traceback("Log", 3)
	local key = (tostring(l) .. tostring(f))
	if level < logLevel then
		return LogItemBlank.new(self, Log.LevelNames[level], traceback, key)
	else
		return LogItem.new(self, Log.LevelNames[level], traceback, key)
	end
end


--[=[
	@param level LogLevel
	@return LogItem
]=]
function Log:At(level)
	return self:_at(level)
end


--[=[
	@return LogItem
	Get a LogItem at the Trace log level.
]=]
function Log:AtTrace()
	return self:_at(Log.Level.Trace)
end


--[=[
	@return LogItem
	Get a LogItem at the Debug log level.
]=]
function Log:AtDebug()
	return self:_at(Log.Level.Debug)
end


--[=[
	@return LogItem
	Get a LogItem at the Info log level.
]=]
function Log:AtInfo()
	return self:_at(Log.Level.Info)
end


--[=[
	@return LogItem
	Get a LogItem at the Warning log level.
]=]
function Log:AtWarning()
	return self:_at(Log.Level.Warning)
end


--[=[
	@return LogItem
	Get a LogItem at the Error log level.
]=]
function Log:AtError()
	return self:_at(Log.Level.Error)
end


--[=[
	@return LogItem
	Get a LogItem at the Fatal log level.
]=]
function Log:AtFatal()
	return self:_at(Log.Level.Fatal)
end


--[=[
	@param condition boolean
	@param ... any
	Asserts the condition and then logs the following
	arguments at the Error level if the condition
	fails.
]=]
function Log:Assert(condition, ...)
	if not condition then
		self:_at(Log.Level.Error):Throw():Log(...)
	end
end


function Log:Destroy()
end


function Log:__tostring()
	return ("Log<%s>"):format(self._name)
end


-- Determine log level:
do
	local function SetLogLevel(name)
		local n = name:lower()
		for levelName,level in pairs(Log.Level) do
			if levelName:lower() == n then
				if IS_STUDIO then
					local attr = (IS_SERVER and "LogLevel" or "LogLevelClient")
					local displayName = (n:sub(1, 1):upper() .. n:sub(2))
					if tostring(workspace:GetAttribute(attr) or "") ~= displayName then
						workspace:SetAttribute(attr, displayName)
					end
				end
				logLevel = level
				return
			end
		end
		error("Unknown log level: " .. tostring(name))
	end
	local configType = type(config)
	assert(configType == "table" or configType == "string", "LogConfig must return a table or a string; got " .. configType)
	if configType == "string" then
		SetLogLevel(config)
	else
		if IS_STUDIO and config.Studio then
			local studioConfigType = type(config.Studio)
			assert(studioConfigType == "table" or studioConfigType == "string", "LogConfig.Studio must be a table or a string; got " .. studioConfigType)
			if studioConfigType == "string" then
				-- Config for Studio:
				SetLogLevel(config.Studio)
			else
				-- Server/Client config for Studio:
				if IS_SERVER then
					local studioServerLevel = config.Studio.Server
					assert(type(studioServerLevel) == "string", "LogConfig.Studio.Server must be a string; got " .. type(studioServerLevel))
					SetLogLevel(studioServerLevel)
				else
					local studioClientLevel = config.Studio.Client
					assert(type(studioClientLevel) == "string", "LogConfig.Studio.Client must be a string; got " .. type(studioClientLevel))
					SetLogLevel(studioClientLevel)
				end
			end
		else
			local default = nil
			local numDefault = 0
			local set = false
			local setK = nil
			for k,specialConfig in pairs(config) do
				if k == "Studio" then continue end
				if type(specialConfig) == "string" then
					default = specialConfig
					numDefault += 1
				elseif type(specialConfig) == "table" then
					-- Check if config can be used if filtered by PlaceId or GameId:
					local canUse, fallthrough = false, false
					if type(specialConfig.PlaceId) == "number" then
						canUse = (specialConfig.PlaceId == game.PlaceId)
					elseif type(specialConfig.PlaceIds) == "table" then
						canUse = (table.find(specialConfig.PlaceIds, game.PlaceId) ~= nil)
					elseif type(specialConfig.GameId) == "number" then
						canUse = (specialConfig.GameId == game.GameId)
					elseif type(specialConfig.GameIds) == "table" then
						canUse = (table.find(specialConfig.GameIds, game.GameId) ~= nil)
					else
						canUse = true
						fallthrough = true
					end
					if not fallthrough then
						assert(not set, ("More than one LogConfig mapping matched (%s and %s)"):format(setK or "", k or ""))
					end
					if canUse then
						if IS_SERVER then
							local serverLevel = specialConfig.Server
							assert(type(serverLevel) == "string", ("LogConfig.%s.Server must be a string; got %s"):format(k, type(serverLevel)))
							SetLogLevel(serverLevel)
							set = true
							setK = k
						else
							local clientLevel = specialConfig.Client
							assert(type(clientLevel) == "string", ("LogConfig.%s.Client must be a string; got %s"):format(k, type(clientLevel)))
							SetLogLevel(clientLevel)
							set = true
							setK = k
						end
					end
				else
					warn(("LogConfig.%s must be a table or a string; got %s"):format(k, typeof(specialConfig)))
				end
			end
			if numDefault > 1 then
				warn("Ambiguous default logging level")
			end
			if default and not set then
				SetLogLevel(default)
			end
		end
	end
	assert(type(logLevel) == "number", "LogLevel failed to be determined")
	if IS_STUDIO then
		local attr = (IS_SERVER and "LogLevel" or "LogLevelClient")
		workspace:GetAttributeChangedSignal(attr):Connect(function()
			SetLogLevel(workspace:GetAttribute(attr))
		end)
	end
end


return Log
