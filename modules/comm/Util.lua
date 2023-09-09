local RunService = game:GetService("RunService")

local Option = require(script.Parent.Parent.Option)

local Util = {}

Util.IsServer = RunService:IsServer()
Util.WaitForChildTimeout = 60
Util.DefaultCommFolderName = "__comm__"
Util.None = newproxy()

function Util.GetCommSubFolder(parent: Instance, subFolderName: string, subFolders: { string }?): Option.Option
	local subFolder: Instance = nil
	if Util.IsServer then
		subFolder = parent:FindFirstChild(subFolderName)
		if not subFolder then
			subFolder = Instance.new("Folder")
			subFolder.Name = subFolderName
			subFolder.Parent = parent
		end

		if subFolders then
			for _, t in subFolders do
				parent = subFolder
				subFolder = parent:FindFirstChild(t)
				if not subFolder then
					subFolder = Instance.new("Folder")
					subFolder.Name = t
					subFolder.Parent = parent
				end
			end
		end
	else
		subFolder = parent:WaitForChild(subFolderName, Util.WaitForChildTimeout)

		if subFolders then
			local parent
			for _, t in subFolders do
				subFolder = subFolder:WaitForChild(t, Util.WaitForChildTimeout)
			end
		end
	end
	return Option.Wrap(subFolder)
end

return Util
