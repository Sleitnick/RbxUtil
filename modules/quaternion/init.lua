--!strict

--[[
	Algorithmic credit: https://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/index.htm
]]

--[=[
	@within Quaternion
	@interface Quaternion
	.X number
	.Y number
	.Z number
	.W number

	Similar to Vector3s, Quaternions are immutable. You cannot manually set the individual properties
	of a Quaternion. Instead, a new Quaternion must first be constructed.
]=]
export type Quaternion = {
	X: number,
	Y: number,
	Z: number,
	W: number,

	Dot: (self: Quaternion, other: Quaternion) -> number,
	Slerp: (self: Quaternion, other: Quaternion, alpha: number) -> Quaternion,
	Angle: (self: Quaternion, other: Quaternion) -> number,
	RotateTowards: (self: Quaternion, other: Quaternion, maxRadiansDelta: number) -> Quaternion,
	ToCFrame: (self: Quaternion, position: Vector3?) -> CFrame,
	ToEulerAngles: (self: Quaternion) -> Vector3,
	ToAxisAngle: (self: Quaternion) -> (Vector3, number),
	Inverse: (self: Quaternion) -> Quaternion,
	Conjugate: (self: Quaternion) -> Quaternion,
	Normalize: (self: Quaternion) -> Quaternion,
	Magnitude: (self: Quaternion) -> number,
	SqrMagnitude: (self: Quaternion) -> number,
}

local EPSILON = 1e-5

--[=[
	@class Quaternion
	Represents a Quaternion. Quaternions are 4D structs that represent rotations
	in 3D space. Quaternions are often used in 3D graphics to avoid the ambiguity
	that comes with Euler angles (e.g. gimbal lock).

	Roblox represents the transformation of an object via CFrame values, which are
	matrices that hold positional and rotational information. Quaternions can be converted
	to and from CFrame values through the `ToCFrame` method and `cframe` constructor.
]=]
local Quaternion = {}
Quaternion.__index = Quaternion

--[=[
	Constructs a Quaternion.

	:::caution
	The `new` constructor assumes the given arguments represent a proper Quaternion. This
	constructor should only be used if you really know what you're doing.
]=]
function Quaternion.new(x: number, y: number, z: number, w: number): Quaternion
	local self = setmetatable({
		X = x,
		Y = y,
		Z = z,
		W = w,
	}, Quaternion) :: any

	table.freeze(self)

	return self
end

--[=[
	Constructs a Quaternion from Euler angles (radians).

	```lua
	-- Quaternion rotated 45 degrees on the Y axis:
	local quat = Quaternion.euler(0, math.rad(45), 0)
	```
]=]
function Quaternion.euler(x: number, y: number, z: number): Quaternion
	local cx = math.cos(x * 0.5)
	local cy = math.cos(y * 0.5)
	local cz = math.cos(z * 0.5)
	local sx = math.sin(x * 0.5)
	local sy = math.sin(y * 0.5)
	local sz = math.sin(z * 0.5)

	return Quaternion.new(
		cx * sy * sz + cy * cz * sx,
		cx * cz * sy - cy * sx * sz,
		cx * cy * sz - cz * sx * sy,
		sx * sy * sz + cx * cy * cz
	)
end

--[=[
	Constructs a Quaternion representing a rotation of `angle` radians around `axis`.

	```lua
	-- Quaternion rotated 45 degrees on the Y axis:
	local quat = Quaternion.axisAngle(Vector3.yAxis, math.rad(45))
	```
]=]
function Quaternion.axisAngle(axis: Vector3, angle: number): Quaternion
	local halfAngle = angle / 2
	local sin = math.sin(halfAngle)

	return Quaternion.new(sin * axis.X, sin * axis.Y, sin * axis.Z, math.cos(halfAngle))
end

--[=[
	Constructs a Quaternion representing a rotation facing `forward` direction, where
	`upwards` represents the upwards direction (this defaults to `Vector3.yAxis`).

	```lua
	-- Create a quaternion facing the same direction as the camera:
	local camCf = workspace.CurrentCamera.CFrame
	local quat = Quaternion.lookRotation(camCf.LookVector, camCf.UpVector)
	```
]=]
function Quaternion.lookRotation(forward: Vector3, upwards: Vector3?): Quaternion
	local up = if upwards == nil then Vector3.yAxis else upwards.Unit
	forward = forward.Unit

	local v1 = forward
	local v2 = up:Cross(v1)
	local v3 = v1:Cross(v2)

	local m00 = v2.X
	local m01 = v2.Y
	local m02 = v2.Z
	local m10 = v3.X
	local m11 = v3.Y
	local m12 = v3.Z
	local m20 = v1.X
	local m21 = v1.Y
	local m22 = v1.Z

	local n8 = m00 + m11 + m22

	if n8 > 0 then
		local n = math.sqrt(n8 + 1)

		return Quaternion.new((m12 - m21) * n, (m20 - m02) * n, (m01 - m10) * n, n * 0.5)
	end

	if m00 >= m11 and m00 >= m22 then
		local n7 = math.sqrt(((1 + m00) - m11) - m22)
		local n4 = 0.5 / n7

		return Quaternion.new(0.5 * n7, (m01 + m10) * n4, (m02 + m20) * n4, (m12 - m21) * n4)
	end

	if m11 > m22 then
		local n6 = math.sqrt(((1 + m11) - m00) - m22)
		local n3 = 0.5 / n6

		return Quaternion.new((m10 + m01) * n3, 0.5 * n6, (m21 + m12) * n3, (m20 - m02) * n3)
	end

	local n5 = math.sqrt(((1 + m22) - m00) - m11)
	local n2 = 0.5 / n5

	return Quaternion.new((m20 + m02) * n2, (m21 + m12) * n2, 0.5 * n5, (m01 - m10) * n2)
end

--[=[
	Constructs a Quaternion from the rotation components of the given `cframe`.

	This method ortho-normalizes the CFrame value, so there is no need to do this yourself
	before calling the function.

	```lua
	-- Create a Quaternion representing the rotational CFrame of a part:
	local quat = Quaternion.cframe(somePart.CFrame)
	```
]=]
function Quaternion.cframe(cframe: CFrame): Quaternion
	local _, _, _, m00, m01, m02, m10, m11, m12, m20, m21, m22 = cframe:Orthonormalize():GetComponents()

	local x, y, z, w

	local trace = m00 + m11 + m22
	if trace > 0 then
		local s = math.sqrt(trace + 1) * 2
		x = (m21 - m12) / s
		y = (m02 - m20) / s
		z = (m10 - m01) / s
		w = 0.25 * s
	elseif m00 > m11 and m00 > m22 then
		local s = math.sqrt(1 + m00 - m11 - m22) * 2
		x = 0.25 * s
		y = (m01 + m10) / s
		z = (m02 + m20) / s
		w = (m21 - m12) / s
	elseif m11 > m22 then
		local s = math.sqrt(1 + m11 - m00 - m22) * 2
		x = (m01 + m10) / s
		y = 0.25 * s
		z = (m12 + m21) / s
		w = (m02 - m20) / s
	else
		local s = math.sqrt(1 + m22 - m00 - m11) * 2
		x = (m02 + m20) / s
		y = (m12 + m21) / s
		z = 0.25 * s
		w = (m10 - m01) / s
	end

	return Quaternion.new(x, y, z, w)
end

--[=[
	@method Dot
	@within Quaternion
	@param other Quaternion
	@return number
	
	Calculates the dot product between the two Quaternions.

	```lua
	local dot = quatA:Dot(quatB)
	```
]=]
function Quaternion.Dot(self: Quaternion, other: Quaternion): number
	return self.X * other.X + self.Y * other.Y + self.Z * other.Z + self.W * other.W
end

--[=[
	@method Slerp
	@within Quaternion
	@param other Quaternion
	@param t number
	@return Quaternion

	Calculates a spherical interpolation between the two Quaternions. Parameter `t` represents
	the percentage between the two rotations, from a range of `[0, 1]`.

	Spherical interpolation is great for smoothing or animating between quaternions.

	```lua
	local midWay = quatA:Slerp(quatB, 0.5)
	```
]=]
function Quaternion.Slerp(a: Quaternion, b: Quaternion, t: number): Quaternion
	local cosOmega = a:Dot(b)
	local flip = false

	if cosOmega < 0 then
		flip = true
		cosOmega = -cosOmega
	end

	local s1, s2

	if cosOmega > (1 - EPSILON) then
		s1 = 1 - t
		s2 = if flip then -t else t
	else
		local omega = math.acos(cosOmega)
		local invSinOmega = 1 / math.sin(omega)

		s1 = math.sin((1 - t) * omega) * invSinOmega
		s2 = if flip then -math.sin(t * omega) * invSinOmega else math.sin(t * omega) * invSinOmega
	end

	return Quaternion.new(s1 * a.X + s2 * b.X, s1 * a.Y + s2 * b.Y, s1 * a.Z + s2 * b.Z, s1 * a.W + s2 * b.W)
end

--[=[
	@method Angle
	@within Quaternion
	@param other Quaternion
	@return number

	Calculates the angle (radians) between the two Quaternions.

	```lua
	local angle = quatA:Angle(quatB)
	```
]=]
function Quaternion.Angle(self: Quaternion, other: Quaternion): number
	local dot = math.min(math.abs(self:Dot(other)), 1)
	local angle = if dot > (1 - EPSILON) then 0 else math.acos(dot) * 2

	return angle
end

--[=[
	@method RotateTowards
	@within Quaternion
	@param other Quaternion
	@param maxRadiansDelta number
	@return Quaternion

	Constructs a new Quaternion that rotates from this Quaternion to the `other` quaternion, with a maximum
	rotation of `maxRadiansDelta`. Internally, this calls `Slerp`, but limits the movement to `maxRadiansDelta`.

	```lua
	-- Rotate from quatA to quatB, but only by 10 degrees:
	local q = quatA:RotateTowards(quatB, math.rad(10))
	```
]=]
function Quaternion.RotateTowards(self: Quaternion, other: Quaternion, maxRadiansDelta: number): Quaternion
	local angle = self:Angle(other)

	if angle == 0 then
		return self
	end

	local alpha = maxRadiansDelta / angle

	return self:Slerp(other, alpha)
end

--[=[
	@method ToCFrame
	@within Quaternion
	@param position Vector3?
	@return CFrame

	Constructs a CFrame value representing the Quaternion. An optional `position` Vector can be given to
	represent the position of the CFrame in 3D space. This defaults to `Vector3.zero`.

	```lua
	-- Construct a CFrame from the quaternion, where the position will be at the origin point:
	local cf = quat:ToCFrame()

	-- Construct a CFrame with a given position:
	local cf = quat:ToCFrame(someVector3)

	-- e.g., set a part's CFrame:
	local part = workspace.Part
	local quat = Quaternion.axisAngle(Vector3.yAxis, math.rad(45))
	local cframe = quat:ToCFrame(part.Position) -- Construct CFrame with a positional component
	part.CFrame = cframe
	```
]=]
function Quaternion.ToCFrame(self: Quaternion, position: Vector3?): CFrame
	local pos = if position == nil then Vector3.zero else position

	return CFrame.new(pos.X, pos.Y, pos.Z, self.X, self.Y, self.Z, self.W)
end

--[=[
	@method ToEulerAngles
	@within Quaternion
	@return Vector3

	Calculates the Euler angles (radians) that represent the Quaternion.

	```lua
	local euler = quat:ToEulerAngles()
	print(euler.X, euler.Y, euler.Z)
	```
]=]
function Quaternion.ToEulerAngles(self: Quaternion): Vector3
	local sinrCosp = 2 * (self.W * self.X + self.Y * self.Z)
	local cosrCosp = 1 - 2 * (self.X * self.X + self.Y * self.Y)
	local x = math.atan2(sinrCosp, cosrCosp)

	local sinp = math.sqrt(1 + 2 * (self.W * self.Y - self.X * self.Z))
	local cosp = math.sqrt(1 - 2 * (self.W * self.Y - self.X * self.Z))
	local z = 2 * math.atan2(sinp, cosp) - math.pi / 2

	local sinyCosp = 2 * (self.W * self.Z + self.X * self.Y)
	local cosyCosp = 1 - 2 * (self.Y * self.Y + self.Z * self.Z)
	local y = math.atan2(sinyCosp, cosyCosp)

	return Vector3.new(x, y, z)
end

--[=[
	@method ToAxisAngle
	@within Quaternion
	@return (Vector3, number)

	Calculates the axis and angle representing the Quaternion.

	```lua
	local axis, angle = quat:ToAxisAngle()
	```
]=]
function Quaternion.ToAxisAngle(self: Quaternion): (Vector3, number)
	local scale = math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)

	if math.abs(scale) < EPSILON or self.W > 1 or self.W < -1 then
		return Vector3.yAxis, 0
	end

	local invScale = 1 / scale

	local axis = Vector3.new(self.X * invScale, self.Y * invScale, self.Z * invScale)
	local angle = 2 * math.acos(self.W)

	return axis, angle
end

--[=[
	@method Inverse
	@within Quaternion
	@return Quaternion

	Returns the inverse of the Quaternion.

	```lua
	local quatInverse = quat:Inverse()
	```
]=]
function Quaternion.Inverse(self: Quaternion): Quaternion
	local dot = self:Dot(self)
	local invNormal = 1 / dot
	return Quaternion.new(-self.X * invNormal, -self.Y * invNormal, -self.Z * invNormal, self.W * invNormal)
end

--[=[
	@method Conjugate
	@within Quaternion
	@return Quaternion

	Returns the conjugate of the Quaternion. This is equal to `Quaternion.new(-X, -Y, -Z, W)`.

	```lua
	local quatConjugate = quat:Conjugate()
	```
]=]
function Quaternion.Conjugate(self: Quaternion): Quaternion
	return Quaternion.new(-self.X, -self.Y, -self.Z, self.W)
end

--[=[
	@method Normalize
	@within Quaternion
	@return Quaternion

	Returns the normalized representation of the Quaternion.

	```lua
	local quatNormalized = quat:Normalize()
	```
]=]
function Quaternion.Normalize(self: Quaternion): Quaternion
	local magnitude = self:Magnitude()

	if magnitude < EPSILON then
		return Quaternion.identity
	end

	return Quaternion.new(self.X / magnitude, self.Y / magnitude, self.Z / magnitude, self.W / magnitude)
end

--[=[
	@method Magnitude
	@within Quaternion
	@return number

	Calculates the magnitude of the Quaternion.

	```lua
	local magnitude = quat:Magnitude()
	```
]=]
function Quaternion.Magnitude(self: Quaternion): number
	return math.sqrt(self:Dot(self))
end

--[=[
	@method SqrMagnitude
	@within Quaternion
	@return number

	Calculates the square magnitude of the Quaternion.

	```lua
	local squareMagnitude = quat:Magnitude()
	```
]=]
function Quaternion.SqrMagnitude(self: Quaternion): number
	return self:Dot(self)
end

function Quaternion._MulVector3(self: Quaternion, other: Vector3): Vector3
	local x = self.X * 2
	local y = self.Y * 2
	local z = self.Z * 2

	local xx = self.X * x
	local yy = self.Y * y
	local zz = self.Z * z
	local xy = self.X * y
	local xz = self.X * z
	local yz = self.Y * z
	local wx = self.W * x
	local wy = self.W * y
	local wz = self.W * z

	return Vector3.new(
		(1 - (yy + zz)) * other.X + (xy - wz) * other.Y + (xz + wy) * other.Z,
		(xy + wz) * other.X + (1 - (xx + zz)) * other.Y + (yz - wx) * other.Z,
		(xz - wy) * other.X + (yz + wx) * other.Y + (1 - (xx + yy)) * other.Z
	)
end

function Quaternion._MulQuaternion(self: Quaternion, other: Quaternion): Quaternion
	return Quaternion.new(
		self.W * other.X + self.X * other.W + self.Y * other.Z - self.Z * other.Y,
		self.W * other.Y + self.Y * other.W + self.Z * other.X - self.X * other.Z,
		self.W * other.Z + self.Z * other.W + self.X * other.Y - self.Y * other.X,
		self.W * other.W - self.X * other.X - self.Y * other.Y - self.Z * other.Z
	)
end

--[=[
	Multiplication metamethod. A Quaternion can be multiplied with another Quaternion or
	a Vector3.

	```lua
	local quat = quatA * quatB
	local vec = quatA * vecA
	```
]=]
function Quaternion.__mul(self: Quaternion, other: Quaternion | Vector3): Quaternion | Vector3
	local t = typeof(other)
	if t == "Vector3" then
		return Quaternion._MulVector3(self, other :: any)
	elseif t == "table" and getmetatable(other :: any) == Quaternion then
		return Quaternion._MulQuaternion(self, (other :: any) :: Quaternion)
	else
		error(`cannot multiply quaternion with type {t}`, 2)
	end
end

function Quaternion.__unm(self: Quaternion): Quaternion
	return Quaternion.new(-self.X, -self.Y, -self.Z, -self.W)
end

function Quaternion.__eq(self: Quaternion, other: Quaternion): boolean
	return self.X == other.X and self.Y == other.Y and self.Z == other.Z and self.W == other.W
end

function Quaternion.__tostring(self: Quaternion): string
	return `{self.X}, {self.Y}, {self.Z}, {self.W}`
end

--[=[
	@prop identity Quaternion
	@readonly
	@within Quaternion

	Identity Quaternion. Equal to `Quaternion.new(0, 0, 0, 1)`.
]=]
Quaternion.identity = Quaternion.new(0, 0, 0, 1)

return {
	new = Quaternion.new,
	euler = Quaternion.euler,
	axisAngle = Quaternion.axisAngle,
	lookRotation = Quaternion.lookRotation,
	cframe = Quaternion.cframe,

	identity = Quaternion.identity,
}
