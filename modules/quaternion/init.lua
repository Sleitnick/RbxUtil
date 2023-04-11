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
	matrices that hold position and rotation in 3D space. Quaternions can be converted
	to CFrame values through the `ToCFrame` method.
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
	Constructs a Quaternion from Euler angles.
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
]=]
function Quaternion.axisAngle(axis: Vector3, angle: number): Quaternion
	local halfAngle = angle / 2
	local sin = math.sin(halfAngle)

	return Quaternion.new(sin * axis.X, sin * axis.Y, sin * axis.Z, math.cos(halfAngle))
end

--[=[
	Constructs a Quaternion representing a rotation facing `forward` direction, where
	`upwards` represents the upwards direction (this defaults to `Vector3.yAxis`).
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
	Calculates the dot product between the two Quaternions.
]=]
function Quaternion:Dot(other: Quaternion): number
	return self.X * other.X + self.Y * other.Y + self.Z * other.Z + self.W * other.W
end

--[=[
	Calculates a spherical interpolation between the two Quaternions. Parameter `t` represents
	the percentage between the two rotations, from a range of `[0, 1]`.
]=]
function Quaternion:Slerp(b: Quaternion, t: number): Quaternion
	local a = self

	local cosHalfTheta = a:Dot(b)
	if math.abs(cosHalfTheta) >= 1 then
		return a
	end

	if cosHalfTheta < 0 then
		b = Quaternion.new(-b.X, -b.Y, -b.Z, -b.W)
		cosHalfTheta = -cosHalfTheta
	end

	local halfTheta = math.cos(cosHalfTheta)
	local sinHalfTheta = math.sqrt(1 - cosHalfTheta * cosHalfTheta)

	if math.abs(sinHalfTheta) < EPSILON then
		return Quaternion.new(
			a.X * 0.5 + b.X * 0.5,
			a.Y * 0.5 + b.Y * 0.5,
			a.Z * 0.5 + b.Z * 0.5,
			a.W * 0.5 + b.W * 0.5
		)
	end

	local ra = math.sin((1 - t) * halfTheta) / sinHalfTheta
	local rb = math.sin(t * halfTheta) / sinHalfTheta

	return Quaternion.new(a.X * ra + b.X * rb, a.Y * ra + b.Y * rb, a.Z * ra + b.Z * rb, a.W * ra + b.W * rb)
end

--[=[
	Calculates the angle between the two Quaternions.
]=]
function Quaternion:Angle(other: Quaternion): number
	local dot = math.min(math.abs(self:Dot(other)), 1)
	local angle = if dot > (1 - EPSILON) then 0 else math.acos(dot) * 2

	return angle
end

--[=[
	Constructs a new Quaternion that rotates from this Quaternion to the `other` quaternion, with a maximum
	rotation of `maxRadiansDelta`.
]=]
function Quaternion:RotateTowards(other: Quaternion, maxRadiansDelta: number): Quaternion
	local angle = self:Angle(other)

	if angle == 0 then
		return self
	end

	local alpha = maxRadiansDelta / angle

	return self:Slerp(other, alpha)
end

--[=[
	Constructs a CFrame value representing the Quaternion. An optional `position` Vector can be given to
	represent the position of the CFrame in 3D space. This defaults to `Vector3.zero`.
]=]
function Quaternion:ToCFrame(position: Vector3?): CFrame
	local pos = if position == nil then Vector3.zero else position

	return CFrame.new(pos.X, pos.Y, pos.Z, self.X, self.Y, self.Z, self.W)
end

--[=[
	Calculates the euler angles that represent the Quaternion.
]=]
function Quaternion:ToEulerAngles(): Vector3
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
	Calculates the axis and angle representing the Quaternion.
]=]
function Quaternion:ToAxisAngle(): (Vector3, number)
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
	Returns the inverse of the Quaternion. (Identical to Conjugate.)
]=]
function Quaternion:Inverse(): Quaternion
	return Quaternion.new(-self.X, -self.Y, -self.Z, self.W)
end

--[=[
	Returns the conjugate of the Quaternion. (Identical to Inverse.)
]=]
function Quaternion:Conjugate(): Quaternion
	return Quaternion.new(-self.X, -self.Y, -self.Z, self.W)
end

--[=[
	Returns the normalized representation of the Quaternion.
]=]
function Quaternion:Normalize(): Quaternion
	local magnitude = self:Magnitude()

	if magnitude < EPSILON then
		return Quaternion.identity
	end

	return Quaternion.new(self.X / magnitude, self.Y / magnitude, self.Z / magnitude, self.W / magnitude)
end

--[=[
	Calculates the magnitude of the Quaternion.
]=]
function Quaternion:Magnitude(): number
	return math.sqrt(self:Dot(self))
end

--[=[
	Calculates the square magnitude of the Quaternion.
]=]
function Quaternion:SqrMagnitude(): number
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

function Quaternion.__mul(self: Quaternion, other): Quaternion | Vector3
	local t = typeof(other)
	if t == "Vector3" then
		return Quaternion._MulVector3(self, other)
	elseif t == "table" and getmetatable(other :: any) == Quaternion then
		return Quaternion._MulQuaternion(self, (other :: any) :: Quaternion)
	else
		error(`cannot multiply quaternion with type {t}`, 2)
	end
end

--[=[
	@prop identity Quaternion
	@within Quaternion

	Identity Quaternion.
]=]
Quaternion.identity = Quaternion.new(0, 0, 0, 1)

return {
	new = Quaternion.new,
	euler = Quaternion.euler,
	axisAngle = Quaternion.axisAngle,
	lookRotation = Quaternion.lookRotation,

	identity = Quaternion.identity,
}
