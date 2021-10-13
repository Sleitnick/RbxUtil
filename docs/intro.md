---
sidebar_position: 1
---

# Getting Started

These Roblox utility modules can be acquired using [Wally](https://wally.run/), a package manager for Roblox.

## Wally Configuration
Once Wally is installed, run `wally init` on your project directory, and then add the various utility modules found here as dependencies. For example, the following could be a `wally.toml` file for a project that includes a few of these modules:
```toml
[package]
name = "your_name/your_project"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Signal = "sleitnick/signal@^1.0"
TableUtil = "slietnick/table-util@^1.0"
```

To install these dependencies, run `wally install` within your project. Wally will create a Package folder in your directory with the installed dependencies.

## Rojo Configuration
The Package folder created by Wally should be synced into Roblox Studio through your Rojo configuration. For instance, a Rojo configuration might have the following entry to sync the Packages folder into ReplicatedStorage:
```json
{
	"name": "rbx-util-example",
	"tree": {
		"$className": "DataModel",
		"ReplicatedStorage": {
			"$className": "ReplicatedStorage",
			"Packages": {
				"$path": "Packages"
			}
		}
	}
}
```

## Usage Example
The installed dependencies can now be used in scripts, such as the following:
```lua
-- Reference folder with packages:
local Packages = game:GetService("ReplicatedStorage").Packages

-- Require the utility modules:
local Signal = require(Packages.Signal)
local TableUtil = require(Packages.TableUtil)

-- Use the modules:
local signal = Signal.new()
signal:Connect(function(data)
	local randomizedData = TableUtil.Shuffle(data)
	print(randomizedData)
end)
signal:Fire({"A", "B", "C"})
```
