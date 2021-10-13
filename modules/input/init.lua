-- Input
-- Stephen Leitnick
-- October 10, 2021

--[=[
	@class Input

	The Input module provides access to various user input classes.

	- [PreferredInput](/api/PreferredInput)
	- [Mouse](/api/Mouse)
	- [Keyboard](/api/Keyboard)
	- [Touch](/api/Touch)

	```lua
	local Input = require(packages.Input)

	local PreferredInput = Input.PreferredInput
	local Mouse = Input.Mouse
	local Keyboard = Input.Keyboard
	local Touch = Input.Touch
	```
]=]
local Input = {
	PreferredInput = require(script.PreferredInput);
	Mouse = require(script.Mouse);
	Keyboard = require(script.Keyboard);
	Touch = require(script.Touch);
}

return Input
