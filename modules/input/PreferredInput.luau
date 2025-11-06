--!strict

--[=[
	@class PreferredInput
	@client

	A helper library for observing the preferred user input of the
	player. This is useful for determining what input schemes
	to use during gameplay. A player might switch from using
	a mouse to a gamepad mid-game, and it is important for the
	game to respond to this change.

	The PreferredInput library is part of the Input package.

	```lua
	local PreferredInput = require(packages.Input).PreferredInput
	```
]=]
--[=[
	@within PreferredInput
	@function observe
	@param handler (preferred: Enum.PreferredInput) -> (() -> ())?
	@return () -> ()

	Observes the preferred input. In other words, the handler function will
	be fired immediately, as well as any time the preferred input changes.

	The returned function can be called to disconnect the observer.

	```lua
	local disconnect = PreferredInput.observe(function(preferred)
		-- Fires immediately & any time the preferred input changes
		print(preferred)

		return function()
			-- Preferred input has changed
		end
	end)

	-- If/when desired, observer can be stopped by calling the returned function:
	disconnect()
	```
]=]
--[=[
	@within PreferredInput
	@function get
	@return Enum.PreferredInput

	Gets the preferred input. This is equivalent to
	[`UserInputService.PreferredInput`](https://create.roblox.com/docs/reference/engine/classes/UserInputService#PreferredInput).
]=]

local UserInputService = game:GetService("UserInputService")

local PreferredInput = {}

function PreferredInput.observe(callback: (preferred: Enum.PreferredInput) -> (() -> ())?)
	local cleanup: (() -> ())? = nil
	local id = 0

	local function onPreferredInputChanged()
		id += 1
		local observeId = id

		local cleanupFn = callback(UserInputService.PreferredInput)
		if typeof(cleanupFn) == "function" then
			if id == observeId then
				cleanup = cleanupFn
			else
				task.spawn(cleanupFn)
			end
		end
	end

	task.spawn(onPreferredInputChanged)
	local conn = UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(onPreferredInputChanged)

	return function()
		conn:Disconnect()
		if typeof(cleanup) == "function" then
			task.spawn(cleanup)
			cleanup = nil
		end
	end
end

function PreferredInput.get()
	return UserInputService.PreferredInput
end

return PreferredInput
