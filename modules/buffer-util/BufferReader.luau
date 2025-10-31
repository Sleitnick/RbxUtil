--!native

local BufferWriter = require(script.Parent.BufferWriter)
local DataTypeBuffer = require(script.Parent.DataTypeBuffer)
local Types = require(script.Parent.Types)

--[=[
	@class BufferReader
	
	A BufferReader is an abstraction wrapper for `buffer` objects
	that provides a convenient way of reading out data from buffers.
]=]
local BufferReader = {}
BufferReader.__index = BufferReader

-- these don't have fast call yet
local buffer_fromstring = buffer.fromstring

local function fromBuffer(buf: buffer): Types.BufferReader
	return setmetatable({
		_buffer = buf,
		_size = buffer.len(buf),
		_cursor = 0,
	}, BufferReader) :: never
end
local function fromString(str: string)
	return fromBuffer(buffer_fromstring(str))
end

function BufferReader.new(buf: string | buffer | Types.BufferWriter): Types.BufferReader
	if type(buf) == "string" then
		return fromString(buf)
	elseif type(buf) == "buffer" then
		return fromBuffer(buf)
	elseif type(buf) == "table" and getmetatable(buf :: any) == BufferWriter then
		return fromBuffer((buf :: never)._buffer)
	end

	error(`expected string or buffer; got {typeof(buf)}`)
end

BufferReader.fromBuffer = fromBuffer
BufferReader.fromString = fromString

local function assertSize(self, desiredSize: number)
	if desiredSize > self._size then
		error("cursor out of bounds", 3)
	end
end

--[=[
	Read a signed 8-bit integer from the buffer.
]=]
function BufferReader:ReadInt8(): number
	local cursor = self._cursor
	assertSize(self, cursor + 1)
	local n = buffer.readi8(self._buffer, cursor)
	self._cursor = cursor + 1
	return n
end

--[=[
	Read an unsigned 8-bit integer from the buffer.
]=]
function BufferReader:ReadUInt8(): number
	local cursor = self._cursor
	assertSize(self, cursor + 1)
	local n = buffer.readu8(self._buffer, cursor)
	self._cursor = cursor + 1
	return n
end
local readUInt8 = BufferReader.ReadUInt8

--[=[
	Read a signed 16-bit integer from the buffer.
]=]
function BufferReader:ReadInt16(): number
	local cursor = self._cursor
	assertSize(self, cursor + 2)
	local n = buffer.readi16(self._buffer, cursor)
	self._cursor = cursor + 2
	return n
end

--[=[
	Read an unsigned 16-bit integer from the buffer.
]=]
function BufferReader:ReadUInt16(): number
	local cursor = self._cursor
	assertSize(self, cursor + 2)
	local n = buffer.readu16(self._buffer, cursor)
	self._cursor = cursor + 2
	return n
end

--[=[
	Read a signed 32-bit integer from the buffer.
]=]
function BufferReader:ReadInt32(): number
	local cursor = self._cursor
	assertSize(self, cursor + 4)
	local n = buffer.readi32(self._buffer, cursor)
	self._cursor = cursor + 4
	return n
end

--[=[
	Read an unsigned 32-bit integer from the buffer.
]=]
function BufferReader:ReadUInt32(): number
	local cursor = self._cursor
	assertSize(self, cursor + 4)
	local n = buffer.readu32(self._buffer, cursor)
	self._cursor = cursor + 4
	return n
end
local readUInt32 = BufferReader.ReadUInt32

--[=[
	Read a 32-bit single-precision float from the buffer.
]=]
function BufferReader:ReadFloat32(): number
	local cursor = self._cursor
	assertSize(self, cursor + 4)
	local n = buffer.readf32(self._buffer, cursor)
	self._cursor = cursor + 4
	return n
end

--[=[
	Read a 64-bit double-precision float from the buffer.
]=]
function BufferReader:ReadFloat64(): number
	local cursor = self._cursor
	assertSize(self, cursor + 8)
	local n = buffer.readf64(self._buffer, cursor)
	self._cursor = cursor + 8
	return n
end

--[=[
	Read a boolean from the buffer.
]=]
function BufferReader:ReadBool(): boolean
	local n = readUInt8(self)
	return n == 1
end

--[=[
	Read a string from the buffer.
	
	:::info
	This assumes the string was written using the `BufferWriter:WriteString()`
	method, which stores an extra integer to mark the size of the string.
	:::
]=]
function BufferReader:ReadString(): string
	local strLen = readUInt32(self)
	local cursor = self._cursor
	assertSize(self, cursor + strLen)
	local s = buffer.readstring(self._buffer, cursor, strLen)
	self._cursor = cursor + strLen
	return s
end

--[=[
	Read a string from the buffer.
	
	:::info
	This assumes the string was written using the `BufferWriter:WriteStringRaw()`.
	:::
]=]
function BufferReader:ReadStringRaw(length: number): string
	length = math.max(0, math.floor(length))
	local cursor = self._cursor
	assertSize(self, cursor + length)
	local s = buffer.readstring(self._buffer, cursor, length)
	self._cursor = cursor + length
	return s
end

--[=[
	Read a DataType from the buffer.

	```lua
	local cframe = reader:ReadDataType(CFrame)
	```
]=]
function BufferReader:ReadDataType<T>(dataType: T): T
	local name = DataTypeBuffer.DataTypesToString[dataType]
	if not name then
		error("unsupported data type", 2)
	end

	local readWrite = DataTypeBuffer.ReadWrite[name]
	return readWrite.read(self)
end

--[=[
	Sets the position of the cursor.
]=]
function BufferReader:SetCursor(position: number)
	position = math.floor(position)
	if position < 0 or position > self._size then
		error(`cursor position {position} out of range [0, {self._size}]`, 3)
	end

	self._cursor = position
end

--[=[
	Returns the position of the cursor.
]=]
function BufferReader:GetCursor(): number
	return self._cursor
end

--[=[
	Resets the position of the cursor.
]=]
function BufferReader:ResetCursor()
	self._cursor = 0
end

--[=[
	Returns the size of the buffer.
]=]
function BufferReader:GetSize(): number
	return self._size
end

--[=[
	Returns the `buffer` object.
]=]
function BufferReader:GetBuffer(): buffer
	return self._buffer
end

function BufferReader:__tostring()
	return "BufferReader"
end

return BufferReader
