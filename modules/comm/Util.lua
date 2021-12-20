local RunService = game:GetService("RunService")

local Option = require(script.Parent.Parent.Option)

local Util = {}

Util.IsServer = RunService:IsServer()
Util.WaitForChildTimeout = 60
Util.DefaultCommFolderName = "__comm__"
Util.None = newproxy()

function Util.GetCommSubFolder(parent: Instance, subFolderName: string): Option.Option
	local subFolder: Instance = nil
	if Util.IsServer then
		subFolder = parent:FindFirstChild(subFolderName)
		if not subFolder then
			subFolder = Instance.new("Folder")
			subFolder.Name = subFolderName
			subFolder.Parent = parent
		end
	else
		subFolder = parent:WaitForChild(subFolderName, Util.WaitForChildTimeout)
	end
	return Option.Wrap(subFolder)
end

return Util
