-- Input
-- Stephen Leitnick
-- October 10, 2021

--[=[
	@class Input

	The Input package provides access to various user input classes.

	- [PreferredInput](/api/PreferredInput)
	- [Mouse](/api/Mouse)
	- [Keyboard](/api/Keyboard)
	- [Touch](/api/Touch)
	- [Gamepad](/api/Gamepad)

	Reference the desired input modules via the Input package to get started:

	```lua
	local PreferredInput = require(Packages.Input).PreferredInput
	local Mouse = require(Packages.Input).Mouse
	local Keyboard = require(Packages.Input).Keyboard
	local Touch = require(Packages.Input).Touch
	local Gamepad = require(Packages.Input).Gamepad
	```
]=]

return {
	PreferredInput = require(script.PreferredInput),
	Mouse = require(script.Mouse),
	Keyboard = require(script.Keyboard),
	Touch = require(script.Touch),
	Gamepad = require(script.Gamepad),
}
