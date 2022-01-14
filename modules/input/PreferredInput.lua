--!strict

-- PreferredInput
-- Stephen Leitnick
-- April 05, 2021


local Signal = require(script.Parent.Parent.Signal)
local EnumList = require(script.Parent.Parent.EnumList)

local UserInputService = game:GetService("UserInputService")

local touchUserInputType = Enum.UserInputType.Touch
local keyboardUserInputType = Enum.UserInputType.Keyboard


--[=[
	@class PreferredInput
	@client

	A helper library for observing the preferred user input of the
	player. This is useful for determining what input schemes
	to use during gameplay. A player might switch from using
	a mouse to a gamepad mid-game, and it is important for the
	game to respond to this change.

	The Preferred class is part of the Input package.

	```lua
	local PreferredInput = require(packages.Input).PreferredInput
	```
]=]
local PreferredInput = {}

--[=[
	@within PreferredInput
	@interface InputType
	@tag Enum
	.MouseKeyboard "MouseKeyboard" -- Prefer mouse and keyboard input
	.Touch "Touch" -- Prefer touch input
	.Gamepad "Gamepad" -- Prefer gamepad input

	Indicates an input schema that the user currently prefers.
]=]

--[=[
	@within PreferredInput
	@prop Changed Signal<InputType>
	@tag Event

	Fired when the preferred InputType changes.

	```lua
	PreferredInput.Changed:Connect(function(preferred)
		if preferred == PreferredInput.InputType.Gamepad then
			-- Prefer gamepad input
		end
	end)
	```
]=]

--[=[
	@within PreferredInput
	@prop InputType InputType
	@readonly
	@tag Enums

	A table containing the InputType enum, e.g. `PreferredInput.InputType.Gamepad`.

	```lua
	if PreferredInput.Current == PreferredInput.InputType.Gamepad then
		-- User prefers gamepad input
	end
	```
]=]

--[=[
	@within PreferredInput
	@prop Current InputType
	@readonly

	The current preferred InputType.

	```lua
	print(PreferredInput.Current)
	```
]=]

PreferredInput.Changed = Signal.new()
PreferredInput.InputType = EnumList.new("InputType", {"MouseKeyboard", "Touch", "Gamepad"})
PreferredInput.Current = PreferredInput.InputType.MouseKeyboard


--[=[
	@param handler (preferred: InputType) -> ()
	@return Connection

	Observes the preferred input. In other words, the handler function will
	be fired immediately, as well as any time the preferred input changes.

	```lua
	local connection = PreferredInput.Observe(function(preferred)
		-- Fires immediately & any time the preferred input changes
		print(preferred)
	end)

	-- If/when desired, the connection to Observe can be cleaned up:
	connection:Disconnect()
	```
]=]
function PreferredInput.Observe(handler)
	task.spawn(handler, PreferredInput.Current)
	return PreferredInput.Changed:Connect(handler)
end


local function SetPreferred(preferred)
	if preferred ~= PreferredInput.Current then
		PreferredInput.Current = preferred
		PreferredInput.Changed:Fire(preferred)
	end
end


local function DeterminePreferred(inputType: Enum.UserInputType)
	if inputType == touchUserInputType then
		SetPreferred(PreferredInput.InputType.Touch)
	elseif inputType == keyboardUserInputType or inputType.Name:sub(1, 5) == "Mouse" then
		SetPreferred(PreferredInput.InputType.MouseKeyboard)
	elseif inputType.Name:sub(1, 7) == "Gamepad" then
		SetPreferred(PreferredInput.InputType.Gamepad)
	end
end


DeterminePreferred(UserInputService:GetLastInputType())
UserInputService.LastInputTypeChanged:Connect(DeterminePreferred)


return PreferredInput
