"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[9755],{77280:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Constructs a Quaternion.\\n\\n:::caution\\nThe `new` constructor assumes the given arguments represent a proper Quaternion. This\\nconstructor should only be used if you really know what you\'re doing.\\n:::","params":[{"name":"x","desc":"","lua_type":"number"},{"name":"y","desc":"","lua_type":"number"},{"name":"z","desc":"","lua_type":"number"},{"name":"w","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"Quaternion\\n"}],"function_type":"static","source":{"line":61,"path":"modules/quaternion/init.luau"}},{"name":"euler","desc":"Constructs a Quaternion from Euler angles (radians).\\n\\n```lua\\n-- Quaternion rotated 45 degrees on the Y axis:\\nlocal quat = Quaternion.euler(0, math.rad(45), 0)\\n```","params":[{"name":"x","desc":"","lua_type":"number"},{"name":"y","desc":"","lua_type":"number"},{"name":"z","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"Quaternion\\n"}],"function_type":"static","source":{"line":82,"path":"modules/quaternion/init.luau"}},{"name":"axisAngle","desc":"Constructs a Quaternion representing a rotation of `angle` radians around `axis`.\\n\\n```lua\\n-- Quaternion rotated 45 degrees on the Y axis:\\nlocal quat = Quaternion.axisAngle(Vector3.yAxis, math.rad(45))\\n```","params":[{"name":"axis","desc":"","lua_type":"Vector3"},{"name":"angle","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"Quaternion\\n"}],"function_type":"static","source":{"line":106,"path":"modules/quaternion/init.luau"}},{"name":"lookRotation","desc":"Constructs a Quaternion representing a rotation facing `forward` direction, where\\n`upwards` represents the upwards direction (this defaults to `Vector3.yAxis`).\\n\\n```lua\\n-- Create a quaternion facing the same direction as the camera:\\nlocal camCf = workspace.CurrentCamera.CFrame\\nlocal quat = Quaternion.lookRotation(camCf.LookVector, camCf.UpVector)\\n```","params":[{"name":"forward","desc":"","lua_type":"Vector3"},{"name":"upwards","desc":"","lua_type":"Vector3?"}],"returns":[{"desc":"","lua_type":"Quaternion\\n"}],"function_type":"static","source":{"line":123,"path":"modules/quaternion/init.luau"}},{"name":"cframe","desc":"Constructs a Quaternion from the rotation components of the given `cframe`.\\n\\nThis method ortho-normalizes the CFrame value, so there is no need to do this yourself\\nbefore calling the function.\\n\\n```lua\\n-- Create a Quaternion representing the rotational CFrame of a part:\\nlocal quat = Quaternion.cframe(somePart.CFrame)\\n```","params":[{"name":"cframe","desc":"","lua_type":"CFrame"}],"returns":[{"desc":"","lua_type":"Quaternion\\n"}],"function_type":"static","source":{"line":180,"path":"modules/quaternion/init.luau"}},{"name":"Dot","desc":"Calculates the dot product between the two Quaternions.\\n\\n```lua\\nlocal dot = quatA:Dot(quatB)\\n```","params":[{"name":"other","desc":"","lua_type":"Quaternion"}],"returns":[{"desc":"","lua_type":"number"}],"function_type":"method","source":{"line":227,"path":"modules/quaternion/init.luau"}},{"name":"Slerp","desc":"Calculates a spherical interpolation between the two Quaternions. Parameter `t` represents\\nthe percentage between the two rotations, from a range of `[0, 1]`.\\n\\nSpherical interpolation is great for smoothing or animating between quaternions.\\n\\n```lua\\nlocal midWay = quatA:Slerp(quatB, 0.5)\\n```","params":[{"name":"other","desc":"","lua_type":"Quaternion"},{"name":"t","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"Quaternion"}],"function_type":"method","source":{"line":247,"path":"modules/quaternion/init.luau"}},{"name":"Angle","desc":"Calculates the angle (radians) between the two Quaternions.\\n\\n```lua\\nlocal angle = quatA:Angle(quatB)\\n```","params":[{"name":"other","desc":"","lua_type":"Quaternion"}],"returns":[{"desc":"","lua_type":"number"}],"function_type":"method","source":{"line":284,"path":"modules/quaternion/init.luau"}},{"name":"RotateTowards","desc":"Constructs a new Quaternion that rotates from this Quaternion to the `other` quaternion, with a maximum\\nrotation of `maxRadiansDelta`. Internally, this calls `Slerp`, but limits the movement to `maxRadiansDelta`.\\n\\n```lua\\n-- Rotate from quatA to quatB, but only by 10 degrees:\\nlocal q = quatA:RotateTowards(quatB, math.rad(10))\\n```","params":[{"name":"other","desc":"","lua_type":"Quaternion"},{"name":"maxRadiansDelta","desc":"","lua_type":"number"}],"returns":[{"desc":"","lua_type":"Quaternion"}],"function_type":"method","source":{"line":306,"path":"modules/quaternion/init.luau"}},{"name":"ToCFrame","desc":"Constructs a CFrame value representing the Quaternion. An optional `position` Vector can be given to\\nrepresent the position of the CFrame in 3D space. This defaults to `Vector3.zero`.\\n\\n```lua\\n-- Construct a CFrame from the quaternion, where the position will be at the origin point:\\nlocal cf = quat:ToCFrame()\\n\\n-- Construct a CFrame with a given position:\\nlocal cf = quat:ToCFrame(someVector3)\\n\\n-- e.g., set a part\'s CFrame:\\nlocal part = workspace.Part\\nlocal quat = Quaternion.axisAngle(Vector3.yAxis, math.rad(45))\\nlocal cframe = quat:ToCFrame(part.Position) -- Construct CFrame with a positional component\\npart.CFrame = cframe\\n```","params":[{"name":"position","desc":"","lua_type":"Vector3?"}],"returns":[{"desc":"","lua_type":"CFrame"}],"function_type":"method","source":{"line":341,"path":"modules/quaternion/init.luau"}},{"name":"ToEulerAngles","desc":"Calculates the Euler angles (radians) that represent the Quaternion.\\n\\n```lua\\nlocal euler = quat:ToEulerAngles()\\nprint(euler.X, euler.Y, euler.Z)\\n```","params":[],"returns":[{"desc":"","lua_type":"Vector3"}],"function_type":"method","source":{"line":359,"path":"modules/quaternion/init.luau"}},{"name":"ToAxisAngle","desc":"Calculates the axis and angle representing the Quaternion.\\n\\n```lua\\nlocal axis, angle = quat:ToAxisAngle()\\n```","params":[],"returns":[{"desc":"","lua_type":"(Vector3, number)"}],"function_type":"method","source":{"line":389,"path":"modules/quaternion/init.luau"}},{"name":"Inverse","desc":"Returns the inverse of the Quaternion.\\n\\n```lua\\nlocal quatInverse = quat:Inverse()\\n```","params":[],"returns":[{"desc":"","lua_type":"Quaternion"}],"function_type":"method","source":{"line":415,"path":"modules/quaternion/init.luau"}},{"name":"Conjugate","desc":"Returns the conjugate of the Quaternion. This is equal to `Quaternion.new(-X, -Y, -Z, W)`.\\n\\n```lua\\nlocal quatConjugate = quat:Conjugate()\\n```","params":[],"returns":[{"desc":"","lua_type":"Quaternion"}],"function_type":"method","source":{"line":432,"path":"modules/quaternion/init.luau"}},{"name":"Normalize","desc":"Returns the normalized representation of the Quaternion.\\n\\n```lua\\nlocal quatNormalized = quat:Normalize()\\n```","params":[],"returns":[{"desc":"","lua_type":"Quaternion"}],"function_type":"method","source":{"line":447,"path":"modules/quaternion/init.luau"}},{"name":"Magnitude","desc":"Calculates the magnitude of the Quaternion.\\n\\n```lua\\nlocal magnitude = quat:Magnitude()\\n```","params":[],"returns":[{"desc":"","lua_type":"number"}],"function_type":"method","source":{"line":468,"path":"modules/quaternion/init.luau"}},{"name":"SqrMagnitude","desc":"Calculates the square magnitude of the Quaternion.\\n\\n```lua\\nlocal squareMagnitude = quat:Magnitude()\\n```","params":[],"returns":[{"desc":"","lua_type":"number"}],"function_type":"method","source":{"line":483,"path":"modules/quaternion/init.luau"}},{"name":"__mul","desc":"Multiplication metamethod. A Quaternion can be multiplied with another Quaternion or\\na Vector3.\\n\\n```lua\\nlocal quat = quatA * quatB\\nlocal vec = quatA * vecA\\n```","params":[{"name":"self","desc":"","lua_type":"Quaternion"},{"name":"other","desc":"","lua_type":"Quaternion | Vector3"}],"returns":[{"desc":"","lua_type":"Quaternion | Vector3\\n"}],"function_type":"static","source":{"line":527,"path":"modules/quaternion/init.luau"}}],"properties":[{"name":"identity","desc":"Identity Quaternion. Equal to `Quaternion.new(0, 0, 0, 1)`.","lua_type":"Quaternion","readonly":true,"source":{"line":560,"path":"modules/quaternion/init.luau"}}],"types":[{"name":"Quaternion","desc":"Similar to Vector3s, Quaternions are immutable. You cannot manually set the individual properties\\nof a Quaternion. Instead, a new Quaternion must first be constructed.","fields":[{"name":"X","lua_type":"number","desc":""},{"name":"Y","lua_type":"number","desc":""},{"name":"Z","lua_type":"number","desc":""},{"name":"W","lua_type":"number","desc":""}],"source":{"line":18,"path":"modules/quaternion/init.luau"}}],"name":"Quaternion","desc":"Represents a Quaternion. Quaternions are 4D structs that represent rotations\\nin 3D space. Quaternions are often used in 3D graphics to avoid the ambiguity\\nthat comes with Euler angles (e.g. gimbal lock).\\n\\nRoblox represents the transformation of an object via CFrame values, which are\\nmatrices that hold positional and rotational information. Quaternions can be converted\\nto and from CFrame values through the `ToCFrame` method and `cframe` constructor.","source":{"line":50,"path":"modules/quaternion/init.luau"}}')}}]);