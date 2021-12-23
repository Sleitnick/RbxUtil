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
	local Preferred = require(packages.Input).Preferred
	```
]=]
local PreferredInput = {}

--[=[
	@within PreferredInput
	@interface InputType
	@tag Enum
	.MouseKeyboard "MouseKeyboard" -- Prefer mouse and keyboard input
	.Touch "MouseKeyboard" -- Prefer touch input
	.Gamepad "Gamepad" -- Prefer gamepad input
]=]
--[=[
	@within PreferredInput
	@prop Changed Signal<InputType>
	@tag Event
	Fired when the preferred InputType changes.
]=]
--[=[
	@within PreferredInput
	@prop InputType InputType
	@readonly
	@tag Enums
	A table containing the InputType enum, e.g. `Preferred.InputType.Gamepad`.
]=]
--[=[
	@within PreferredInput
	@prop Current InputType
	@readonly
	The current preferred InputType.
]=]

PreferredInput.Changed = Signal.new()
PreferredInput.InputType = EnumList.new("InputType", {"MouseKeyboard", "Touch", "Gamepad"})
PreferredInput.Current = PreferredInput.InputType.MouseKeyboard


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
