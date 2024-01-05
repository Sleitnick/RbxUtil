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

function BufferReader.new(buf: string | buffer | Types.BufferWriter): Types.BufferReader
	if typeof(buf) == "string" then
		return BufferReader.fromString(buf)
	elseif typeof(buf) == "buffer" then
		return BufferReader.fromBuffer(buf)
	elseif typeof(buf) == "table" and getmetatable(buf :: any) == BufferWriter then
		return BufferReader.fromBuffer(buf:GetBuffer())
	end

	error(`expected string or buffer; got {typeof(buf)}`)
end

function BufferReader.fromBuffer(buf: buffer)
	local self = setmetatable({
		_buffer = buf,
		_size = buffer.len(buf),
		_cursor = 0,
	}, BufferReader)

	return self
end

function BufferReader.fromString(str: string)
	return BufferReader.fromBuffer(buffer.fromstring(str))
end

function BufferReader:_assertSize(desiredSize: number)
	if desiredSize > self._size then
		error(`cursor out of bounds`, 3)
	end
end

--[=[
	Read a signed 8-bit integer from the buffer.
]=]
function BufferReader:ReadInt8(): number
	self:_assertSize(self._cursor + 1)
	local n = buffer.readi8(self._buffer, self._cursor)
	self._cursor += 1
	return n
end

--[=[
	Read an unsigned 8-bit integer from the buffer.
]=]
function BufferReader:ReadUInt8(): number
	self:_assertSize(self._cursor + 1)
	local n = buffer.readu8(self._buffer, self._cursor)
	self._cursor += 1
	return n
end

--[=[
	Read a signed 16-bit integer from the buffer.
]=]
function BufferReader:ReadInt16(): number
	self:_assertSize(self._cursor + 2)
	local n = buffer.readi16(self._buffer, self._cursor)
	self._cursor += 2
	return n
end

--[=[
	Read an unsigned 16-bit integer from the buffer.
]=]
function BufferReader:ReadUInt16(): number
	self:_assertSize(self._cursor + 2)
	local n = buffer.readu16(self._buffer, self._cursor)
	self._cursor += 2
	return n
end

--[=[
	Read a signed 32-bit integer from the buffer.
]=]
function BufferReader:ReadInt32(): number
	self:_assertSize(self._cursor + 4)
	local n = buffer.readi32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

--[=[
	Read an unsigned 32-bit integer from the buffer.
]=]
function BufferReader:ReadUInt32(): number
	self:_assertSize(self._cursor + 4)
	local n = buffer.readu32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

--[=[
	Read a 32-bit single-precision float from the buffer.
]=]
function BufferReader:ReadFloat32(): number
	self:_assertSize(self._cursor + 4)
	local n = buffer.readf32(self._buffer, self._cursor)
	self._cursor += 4
	return n
end

--[=[
	Read a 64-bit double-precision float from the buffer.
]=]
function BufferReader:ReadFloat64(): number
	self:_assertSize(self._cursor + 8)
	local n = buffer.readf64(self._buffer, self._cursor)
	self._cursor += 8
	return n
end

--[=[
	Read a boolean from the buffer.
]=]
function BufferReader:ReadBool(): boolean
	local n = self:ReadUInt8()
	return n == 1
end

--[=[
	Read a string from the buffer.
	
	:::info
	This assumes the string was written using the `BufferWriter:WriteString()`
	method, which stores an extra integer to mark the size of the string.
]=]
function BufferReader:ReadString(): string
	local strLen = self:ReadUInt32()
	self:_assertSize(self._cursor + strLen)
	local s = buffer.readstring(self._buffer, self._cursor, strLen)
	self._cursor += strLen
	return s
end

--[=[
	Read a string from the buffer.
	
	:::info
	This assumes the string was written using the `BufferWriter:WriteStringRaw()`.
]=]
function BufferReader:ReadStringRaw(length: number): string
	length = math.max(0, math.floor(length))
	self:_assertSize(self._cursor + length)
	local s = buffer.readstring(self._buffer, self._cursor, length)
	self._cursor += length
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
