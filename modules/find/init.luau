--!strict

--[=[
	@class Find

	A utility function for finding objects in the data model hierarchy.

	Similar to `FindFirstChild`, except it explicitly errors if any object
	is not found, as well as a more helpful message as to what wasn't found.

	```lua
	local find = require(ReplicatedStorage.Packages.find)

	-- Find instance "workspace.Some.Folder.Here.Item":
	local item = find(workspace, "Some", "Folder", "Here", "Item")
	```

	In the above example, if "Folder" didn't exist, the function would throw an error with the message: `failed to find instance "Folder" within "Workspace.Some"`.

	The return type is simply `Instance`. Any type-checking should be done on the return value:
	```lua
	local part = find(workspace, "SomePart") :: BasePart -- Blindly assume and type this as a BasePart
	assert(part:IsA("BasePart")) -- Extra optional precaution to ensure type
	```
]=]

local function find(parent: Instance, ...: string): Instance
	local instance = parent

	for i = 1, select("#", ...) do
		local name = (select(i, ...))

		local inst = instance:FindFirstChild(name)
		if inst == nil then
			error(`failed to find instance "{name}" within {instance:GetFullName()}`, 2)
		end

		instance = inst
	end

	return instance
end

return find
