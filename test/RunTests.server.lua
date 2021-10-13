print("Running unit tests...")
require(script.Parent.Packages.TestEZ).TestBootstrap:run({game:GetService("ReplicatedStorage").Modules})
