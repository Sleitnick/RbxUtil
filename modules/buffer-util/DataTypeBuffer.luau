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

DataTypeBuffer.ReadWrite = {} :: {[string]: ReadWritePair}

local NORMAL_ID_TO_VECTOR3 = {
	[0] = Vector3.new(1, 0, 0), -- Enum.NormalId.Right
	[1] = Vector3.new(0, 1, 0), -- Enum.NormalId.Top
	[2] = Vector3.new(0, 0, 1), -- Enum.NormalId.Back
	[3] = Vector3.new(-1, 0, 0), -- Enum.NormalId.Left
	[4] = Vector3.new(0, -1, 0), -- Enum.NormalId.Bottom
	[5] = Vector3.new(0, 0, -1), -- Enum.NormalId.Front
}
local VECTOR3_ONE = Vector3.one
local Cross = VECTOR3_ONE.Cross
local Dot = VECTOR3_ONE.Dot

local readWriteVector2 = {
	write = function(writer: Types.BufferWriter, vector2: Vector2)
		writer:WriteFloat32(vector2.X)
		writer:WriteFloat32(vector2.Y)
	end,

	read = function(reader: Types.BufferReader): Vector2
		local x = reader:ReadFloat32()
		local y = reader:ReadFloat32()
		return Vector2.new(x, y)
	end,
}
local readWriteVector3 = {
	write = function(writer: Types.BufferWriter, vector3: Vector3)
		writer:WriteFloat32(vector3.X)
		writer:WriteFloat32(vector3.Y)
		writer:WriteFloat32(vector3.Z)
	end,

	read = function(reader: Types.BufferReader): Vector3
		local x = reader:ReadFloat32()
		local y = reader:ReadFloat32()
		local z = reader:ReadFloat32()
		return Vector3.new(x, y, z)
	end,
}
local readWriteVector3int16 = {
	write = function(writer: Types.BufferWriter, vector3Int16: Vector3int16)
		writer:WriteInt16(vector3Int16.X)
		writer:WriteInt16(vector3Int16.Y)
		writer:WriteInt16(vector3Int16.Z)
	end,

	read = function(reader: Types.BufferReader): Vector3int16
		local x = reader:ReadInt16()
		local y = reader:ReadInt16()
		local z = reader:ReadInt16()
		return Vector3int16.new(x, y, z)
	end,
}

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
	write = function(writer: Types.BufferWriter, cframe: CFrame)
		local upVector = cframe.UpVector
		local rightVector = cframe.RightVector

		local rightAligned = math.abs(Dot(rightVector, VECTOR3_ONE))
		local upAligned = math.abs(Dot(upVector, VECTOR3_ONE))

		local axisAligned = (math.abs(1 - rightAligned) < 0.00001 or rightAligned == 0)
			and (math.abs(1 - upAligned) < 0.00001 or upAligned == 0)

		if axisAligned then
			local rightNormal: number
			local upNormal: number

			for index = 0, 5 do
				local vector = NORMAL_ID_TO_VECTOR3[index]
				if 1 - Dot(vector, rightVector) < 0.00001 then
					rightNormal = index
				end
				if 1 - Dot(vector, upVector) < 0.00001 then
					upNormal = index
				end
			end

			writer:WriteUInt8(rightNormal * 6 + upNormal)
			readWriteVector3.write(writer, cframe.Position)
		else
			writer:WriteUInt8(0)
			readWriteVector3.write(writer, cframe.Position)
			readWriteVector3.write(writer, cframe.XVector)
			readWriteVector3.write(writer, cframe.YVector)
			readWriteVector3.write(writer, cframe.ZVector)
		end
	end,

	read = function(reader: Types.BufferReader): CFrame
		local id = reader:ReadUInt8()
		local position = readWriteVector3.read(reader)
		if id == 0 then
			local xVector = readWriteVector3.read(reader)
			local yVector = readWriteVector3.read(reader)
			local zVector = readWriteVector3.read(reader)
			return CFrame.fromMatrix(position, xVector, yVector, zVector)
		end

		local rightVector = NORMAL_ID_TO_VECTOR3[id // 6]
		local upVector = NORMAL_ID_TO_VECTOR3[id % 6]
		local lookVector = Cross(rightVector, upVector)
		return CFrame.fromMatrix(position, rightVector, upVector, lookVector)
	end,
}

DataTypeBuffer.ReadWrite.Color3 = {
	write = function(writer: Types.BufferWriter, color3: Color3)
		writer:WriteFloat32(color3.R)
		writer:WriteFloat32(color3.G)
		writer:WriteFloat32(color3.B)
	end,

	read = function(reader: Types.BufferReader): Color3
		local r = reader:ReadFloat32()
		local g = reader:ReadFloat32()
		local b = reader:ReadFloat32()
		return Color3.new(r, g, b)
	end,
}

DataTypeBuffer.ReadWrite.DateTime = {
	write = function(writer: Types.BufferWriter, dateTime: DateTime)
		writer:WriteFloat64(dateTime.UnixTimestampMillis)
	end,

	read = function(reader: Types.BufferReader): DateTime
		local millis = reader:ReadFloat64()
		return DateTime.fromUnixTimestampMillis(millis)
	end,
}

DataTypeBuffer.ReadWrite.Ray = {
	write = function(writer: Types.BufferWriter, ray: Ray)
		readWriteVector3.write(writer, ray.Origin)
		readWriteVector3.write(writer, ray.Direction)
	end,

	read = function(reader: Types.BufferReader): Ray
		local origin = readWriteVector3.read(reader)
		local direction = readWriteVector3.read(reader)
		return Ray.new(origin, direction)
	end,
}

DataTypeBuffer.ReadWrite.Rect = {
	write = function(writer: Types.BufferWriter, rect: Rect)
		readWriteVector2.write(writer, rect.Min)
		readWriteVector2.write(writer, rect.Max)
	end,

	read = function(reader: Types.BufferReader): Rect
		local min = readWriteVector2.read(reader)
		local max = readWriteVector2.read(reader)
		return Rect.new(min, max)
	end,
}

DataTypeBuffer.ReadWrite.Region3 = {
	write = function(writer: Types.BufferWriter, region3: Region3)
		local pos = region3.CFrame.Position
		local sizeHalf = region3.Size * 0.5
		local min = pos - sizeHalf
		local max = pos + sizeHalf
		readWriteVector3.write(writer, min)
		readWriteVector3.write(writer, max)
	end,

	read = function(reader: Types.BufferReader): Region3
		local min = readWriteVector3.read(reader)
		local max = readWriteVector3.read(reader)
		return Region3.new(min, max)
	end,
}

DataTypeBuffer.ReadWrite.Region3int16 = {
	write = function(writer: Types.BufferWriter, region3int16: Region3int16)
		readWriteVector3int16.write(writer, region3int16.Min)
		readWriteVector3int16.write(writer, region3int16.Max)
	end,

	read = function(reader: Types.BufferReader): Region3int16
		local min = readWriteVector3int16.read(reader)
		local max = readWriteVector3int16.read(reader)
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
local readWriteUDim = DataTypeBuffer.ReadWrite.UDim

DataTypeBuffer.ReadWrite.UDim2 = {
	write = function(writer: Types.BufferWriter, udim2: UDim2)
		readWriteUDim.write(writer, udim2.X)
		readWriteUDim.write(writer, udim2.Y)
	end,

	read = function(reader: Types.BufferReader): UDim2
		local x = readWriteUDim.read(reader)
		local y = readWriteUDim.read(reader)
		return UDim2.new(x, y)
	end,
}

DataTypeBuffer.ReadWrite.Vector2 = readWriteVector2
DataTypeBuffer.ReadWrite.Vector3 = readWriteVector3

DataTypeBuffer.ReadWrite.Vector2int16 = {
	write = function(writer: Types.BufferWriter, vector2Int16: Vector2int16)
		writer:WriteInt16(vector2Int16.X)
		writer:WriteInt16(vector2Int16.Y)
	end,

	read = function(reader: Types.BufferReader): Vector2int16
		local x = reader:ReadInt16()
		local y = reader:ReadInt16()
		return Vector2int16.new(x, y)
	end,
}
DataTypeBuffer.ReadWrite.Vector3int16 = readWriteVector3int16

return DataTypeBuffer
