--!native

local Types = require(script.Parent.Types)

type ReadWritePair = {
	read: <T>(reader: Types.BufferReader) -> T,
	write: <T>(writer: Types.BufferWriter, value: T) -> (),
}

local DataTypeBuffer = {}

DataTypeBuffer.DataTypesToString = {
	[BrickColor] = "BrickColor",
	[CFrame] = "CFrame",
	[Color3] = "Color3",
	[DateTime] = "DateTime",
	[Ray] = "Ray",
	[Rect] = "Rect",
	[Region3] = "Region3",
	[Region3int16] = "Region3int16",
	[UDim] = "UDim",
	[UDim2] = "UDim2",
	[Vector2] = "Vector2",
	[Vector3] = "Vector3",
	[Vector2int16] = "Vector2int16",
	[Vector3int16] = "Vector3int16",
}

DataTypeBuffer.ReadWrite = {} :: { [string]: ReadWritePair }

DataTypeBuffer.ReadWrite.BrickColor = {
	write = function(writer: Types.BufferWriter, brickColor: BrickColor)
		writer:WriteUInt16(brickColor.Number)
	end,

	read = function(reader: Types.BufferReader): BrickColor
		local number = reader:ReadUInt16()
		return BrickColor.new(number)
	end,
}

DataTypeBuffer.ReadWrite.CFrame = {
	write = function(writer: Types.BufferWriter, cf: CFrame)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, cf.Position)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, cf.XVector)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, cf.YVector)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, cf.ZVector)
	end,

	read = function(reader: Types.BufferReader): CFrame
		local pos = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		local vx = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		local vy = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		local vz = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		return CFrame.fromMatrix(pos, vx, vy, vz)
	end,
}

DataTypeBuffer.ReadWrite.Color3 = {
	write = function(writer: Types.BufferWriter, c: Color3)
		writer:WriteFloat32(c.R)
		writer:WriteFloat32(c.G)
		writer:WriteFloat32(c.B)
	end,

	read = function(reader: Types.BufferReader): Color3
		local r = reader:ReadFloat32()
		local g = reader:ReadFloat32()
		local b = reader:ReadFloat32()
		return Color3.new(r, g, b)
	end,
}

DataTypeBuffer.ReadWrite.DateTime = {
	write = function(writer: Types.BufferWriter, dt: DateTime)
		writer:WriteFloat64(dt.UnixTimestampMillis)
	end,

	read = function(reader: Types.BufferReader): DateTime
		local millis = reader:ReadFloat64()
		return DateTime.fromUnixTimestampMillis(millis)
	end,
}

DataTypeBuffer.ReadWrite.Ray = {
	write = function(writer: Types.BufferWriter, ray: Ray)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, ray.Origin)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, ray.Direction)
	end,

	read = function(reader: Types.BufferReader): Ray
		local origin = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		local direction = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		return Ray.new(origin, direction)
	end,
}

DataTypeBuffer.ReadWrite.Rect = {
	write = function(writer: Types.BufferWriter, rect: Rect)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, rect.Min)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, rect.Max)
	end,

	read = function(reader: Types.BufferReader): Rect
		local min = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		local max = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		return Rect.new(min, max)
	end,
}

DataTypeBuffer.ReadWrite.Region3 = {
	write = function(writer: Types.BufferWriter, region3: Region3)
		local pos = region3.CFrame.Position
		local sizeHalf = region3.Size * 0.5
		local min = pos - sizeHalf
		local max = pos + sizeHalf
		DataTypeBuffer.ReadWrite.Vector3.write(writer, min)
		DataTypeBuffer.ReadWrite.Vector3.write(writer, max)
	end,

	read = function(reader: Types.BufferReader): Region3
		local min = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		local max = DataTypeBuffer.ReadWrite.Vector3.read(reader)
		return Region3.new(min, max)
	end,
}

DataTypeBuffer.ReadWrite.Region3int16 = {
	write = function(writer: Types.BufferWriter, region3int16: Region3int16)
		DataTypeBuffer.ReadWrite.Vector3int16.write(writer, region3int16.Min)
		DataTypeBuffer.ReadWrite.Vector3int16.write(writer, region3int16.Max)
	end,

	read = function(reader: Types.BufferReader): Region3int16
		local min = DataTypeBuffer.ReadWrite.Vector3int16.read(reader)
		local max = DataTypeBuffer.ReadWrite.Vector3int16.read(reader)
		return Region3int16.new(min, max)
	end,
}

DataTypeBuffer.ReadWrite.UDim = {
	write = function(writer: Types.BufferWriter, udim: UDim)
		writer:WriteFloat32(udim.Scale)
		writer:WriteInt32(udim.Offset)
	end,

	read = function(reader: Types.BufferReader): UDim
		local scale = reader:ReadFloat32()
		local offset = reader:ReadInt32()
		return UDim.new(scale, offset)
	end,
}

DataTypeBuffer.ReadWrite.UDim2 = {
	write = function(writer: Types.BufferWriter, udim2: UDim2)
		DataTypeBuffer.ReadWrite.UDim.write(writer, udim2.X)
		DataTypeBuffer.ReadWrite.UDim.write(writer, udim2.Y)
	end,

	read = function(reader: Types.BufferReader): UDim2
		local x = DataTypeBuffer.ReadWrite.UDim.read(reader)
		local y = DataTypeBuffer.ReadWrite.UDim.read(reader)
		return UDim2.new(x, y)
	end,
}

DataTypeBuffer.ReadWrite.Vector2 = {
	write = function(writer: Types.BufferWriter, v2: Vector2)
		writer:WriteFloat32(v2.X)
		writer:WriteFloat32(v2.Y)
	end,

	read = function(reader: Types.BufferReader): Vector2
		local x = reader:ReadFloat32()
		local y = reader:ReadFloat32()
		return Vector2.new(x, y)
	end,
}

DataTypeBuffer.ReadWrite.Vector3 = {
	write = function(writer: Types.BufferWriter, v3: Vector3)
		writer:WriteFloat32(v3.X)
		writer:WriteFloat32(v3.Y)
		writer:WriteFloat32(v3.Z)
	end,

	read = function(reader: Types.BufferReader): Vector3
		local x = reader:ReadFloat32()
		local y = reader:ReadFloat32()
		local z = reader:ReadFloat32()
		return Vector3.new(x, y, z)
	end,
}

DataTypeBuffer.ReadWrite.Vector2int16 = {
	write = function(writer: Types.BufferWriter, v2: Vector2int16)
		writer:WriteInt16(v2.X)
		writer:WriteInt16(v2.Y)
	end,

	read = function(reader: Types.BufferReader): Vector2int16
		local x = reader:ReadInt16()
		local y = reader:ReadInt16()
		return Vector2int16.new(x, y)
	end,
}

DataTypeBuffer.ReadWrite.Vector3int16 = {
	write = function(writer: Types.BufferWriter, v3: Vector3int16)
		writer:WriteInt16(v3.X)
		writer:WriteInt16(v3.Y)
		writer:WriteInt16(v3.Z)
	end,

	read = function(reader: Types.BufferReader): Vector3int16
		local x = reader:ReadInt16()
		local y = reader:ReadInt16()
		local z = reader:ReadInt16()
		return Vector3int16.new(x, y, z)
	end,
}

return DataTypeBuffer
