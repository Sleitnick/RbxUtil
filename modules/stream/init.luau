--!native
--!strict

--[=[
	@class stream

	The `stream` library allows a stream-like interface abstraction on top of buffers. This is useful
	for reading or writing buffers without having to keep track of the current offset position.

	This library is specifically tailored around fixed-length buffers.

	```lua
	-- Create an empty stream and write some data:
	local s = stream.create(4)
	stream.writeu8(s, 10)
	stream.writeu8(s, 25)
	stream.writeu8(s, 2)
	stream.writeu8(s, 43)

	-- Grab the buffer if needed:
	local buf = stream.buffer(s)

	-- Create a stream from an existing buffer:
	local s = stream.from(buf)
	print(stream.readu8()) -- 10
	print(stream.readu8()) -- 25
	print(stream.readu8()) -- 2
	print(stream.readu8()) -- 43

	-- Move the cursor:
	stream.seek(s, 1)
	print(stream.readu8()) -- 25
	```
]=]

export type Stream = {
	b: buffer,
	l: number,
	o: number,
}

local stream = {}

--[=[
	@within stream

	Create a stream around a new buffer with the given size in bytes.
	
	This is equivalent to `stream.frombuffer(buffer.create(size))`.
]=]
function stream.create(size: number): Stream
	return stream.frombuffer(buffer.create(size))
end

--[=[
	@within stream

	Create a stream around an existing buffer.
]=]
function stream.frombuffer(buf: buffer): Stream
	return {
		b = buf,
		l = buffer.len(buf),
		o = 0,
	}
end

--[=[
	@within stream

	Create a stream from an existing string.
	
	This is equivalent to `stream.frombuffer(buffer.fromstring(size))`.
]=]
function stream.fromstring(str: string): Stream
	local buf = buffer.fromstring(str)
	return {
		b = buf,
		l = buffer.len(buf),
		o = 0,
	}
end

-------------------------------------------------------------------------
-- Read

--[=[
	@within stream
]=]
function stream.readu8(s: Stream): number
	local n = buffer.readu8(s.b, s.o)
	s.o += 1
	return n
end

--[=[
	@within stream
]=]
function stream.readi8(s: Stream): number
	local n = buffer.readi8(s.b, s.o)
	s.o += 1
	return n
end

--[=[
	@within stream
]=]
function stream.readu16(s: Stream): number
	local n = buffer.readu16(s.b, s.o)
	s.o += 2
	return n
end

--[=[
	@within stream
]=]
function stream.readi16(s: Stream): number
	local n = buffer.readi16(s.b, s.o)
	s.o += 2
	return n
end

--[=[
	@within stream
]=]
function stream.readu32(s: Stream): number
	local n = buffer.readu32(s.b, s.o)
	s.o += 4
	return n
end

--[=[
	@within stream
]=]
function stream.readi32(s: Stream): number
	local n = buffer.readi32(s.b, s.o)
	s.o += 4
	return n
end

--[=[
	@within stream
]=]
function stream.readf32(s: Stream): number
	local n = buffer.readf32(s.b, s.o)
	s.o += 4
	return n
end

--[=[
	@within stream
]=]
function stream.readf64(s: Stream): number
	local n = buffer.readf64(s.b, s.o)
	s.o += 8
	return n
end

--[=[
	@within stream
]=]
function stream.readstring(s: Stream, count: number): string
	local str = buffer.readstring(s.b, s.o, count)
	s.o += count
	return str
end

--[=[
	@within stream

	Reads a string previously written using `stream.writelstring`. This function
	assumes that the length of the string is written at the beginning as a u32 int.
]=]
function stream.readlstring(s: Stream): string
	local count = stream.readu32(s)
	return stream.readstring(s, count)
end

--[=[
	@within stream

	Equivalent to `stream.readvectorf32`.
]=]
function stream.readvector(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readf32(b, o + 0)
	local y = buffer.readf32(b, o + 4)
	local z = buffer.readf32(b, o + 8)
	s.o += 12
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectorf32(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readf32(b, o + 0)
	local y = buffer.readf32(b, o + 4)
	local z = buffer.readf32(b, o + 8)
	s.o += 12
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectoru32(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readu32(b, o + 0)
	local y = buffer.readu32(b, o + 4)
	local z = buffer.readu32(b, o + 8)
	s.o += 12
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectori32(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readi32(b, o + 0)
	local y = buffer.readi32(b, o + 4)
	local z = buffer.readi32(b, o + 8)
	s.o += 12
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectoru16(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readu16(b, o + 0)
	local y = buffer.readu16(b, o + 2)
	local z = buffer.readu16(b, o + 4)
	s.o += 6
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectori16(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readi16(b, o + 0)
	local y = buffer.readi16(b, o + 2)
	local z = buffer.readi16(b, o + 4)
	s.o += 6
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectoru8(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readu8(b, o + 0)
	local y = buffer.readu8(b, o + 1)
	local z = buffer.readu8(b, o + 2)
	s.o += 3
	return vector.create(x, y, z)
end

--[=[
	@within stream
]=]
function stream.readvectori8(s: Stream): vector
	local b = s.b
	local o = s.o
	local x = buffer.readi8(b, o + 0)
	local y = buffer.readi8(b, o + 1)
	local z = buffer.readi8(b, o + 2)
	s.o += 3
	return vector.create(x, y, z)
end

-------------------------------------------------------------------------
-- Write

--[=[
	@within stream
]=]
function stream.writeu8(s: Stream, n: number)
	buffer.writeu8(s.b, s.o, n)
	s.o += 1
end

--[=[
	@within stream
]=]
function stream.writei8(s: Stream, n: number)
	buffer.writei8(s.b, s.o, n)
	s.o += 1
end

--[=[
	@within stream
]=]
function stream.writeu16(s: Stream, n: number)
	buffer.writeu16(s.b, s.o, n)
	s.o += 2
end

--[=[
	@within stream
]=]
function stream.writei16(s: Stream, n: number)
	buffer.writei16(s.b, s.o, n)
	s.o += 2
end

--[=[
	@within stream
]=]
function stream.writeu32(s: Stream, n: number)
	buffer.writeu32(s.b, s.o, n)
	s.o += 4
end

--[=[
	@within stream
]=]
function stream.writei32(s: Stream, n: number)
	buffer.writei32(s.b, s.o, n)
	s.o += 4
end

--[=[
	@within stream
]=]
function stream.writef32(s: Stream, n: number)
	buffer.writef32(s.b, s.o, n)
	s.o += 4
end

--[=[
	@within stream
]=]
function stream.writef64(s: Stream, n: number)
	buffer.writef64(s.b, s.o, n)
	s.o += 8
end

--[=[
	@within stream
]=]
function stream.writestring(s: Stream, str: string, count: number?)
	buffer.writestring(s.b, s.o, str, count)
	s.o += count or #str
end

--[=[
	@within stream
]=]
function stream.writelstring(s: Stream, str: string, count: number?)
	stream.writeu32(s, count or #str)
	stream.writestring(s, str, count)
end

--[=[
	@within stream

	Equivalent to `stream.writevectorf32`.
]=]
function stream.writevector(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writef32(b, o + 0, v.x)
	buffer.writef32(b, o + 4, v.x)
	buffer.writef32(b, o + 8, v.x)
	s.o += 12
end

--[=[
	@within stream
]=]
function stream.writevectorf32(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writef32(b, o + 0, v.x)
	buffer.writef32(b, o + 4, v.x)
	buffer.writef32(b, o + 8, v.x)
	s.o += 12
end

--[=[
	@within stream
]=]
function stream.writevectoru32(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writeu32(b, o + 0, v.x)
	buffer.writeu32(b, o + 4, v.x)
	buffer.writeu32(b, o + 8, v.x)
	s.o += 12
end

--[=[
	@within stream
]=]
function stream.writevectori32(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writei32(b, o + 0, v.x)
	buffer.writei32(b, o + 4, v.x)
	buffer.writei32(b, o + 8, v.x)
	s.o += 12
end

--[=[
	@within stream
]=]
function stream.writevectoru16(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writeu16(b, o + 0, v.x)
	buffer.writeu16(b, o + 2, v.x)
	buffer.writeu16(b, o + 4, v.x)
	s.o += 6
end

--[=[
	@within stream
]=]
function stream.writevectori16(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writei16(b, o + 0, v.x)
	buffer.writei16(b, o + 2, v.x)
	buffer.writei16(b, o + 4, v.x)
	s.o += 6
end

--[=[
	@within stream
]=]
function stream.writevectoru8(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writeu8(b, o + 0, v.x)
	buffer.writeu8(b, o + 1, v.x)
	buffer.writeu8(b, o + 2, v.x)
	s.o += 3
end

--[=[
	@within stream
]=]
function stream.writevectori8(s: Stream, v: vector)
	local b = s.b
	local o = s.o
	buffer.writei8(b, o + 0, v.x)
	buffer.writei8(b, o + 1, v.x)
	buffer.writei8(b, o + 2, v.x)
	s.o += 3
end

-------------------------------------------------------------------------

--[=[
	@within stream

	Returns the length of the backing buffer.
]=]
function stream.len(s: Stream): number
	return s.l
end

--[=[
	@within stream

	Returns the position of the stream's cursor.
]=]
function stream.pos(s: Stream): number
	return s.o
end

--[=[
	@within stream

	Copy `count` bytes from `source` into `target`. The provided streams' cursors are
	incremented by `count`.
]=]
function stream.copy(target: Stream, source: Stream, count: number)
	buffer.copy(target.b, target.o, source.b, source.o, count)
	target.o += count
	source.o += count
end

--[=[
	@within stream

	Copy `count` bytes from the `source` stream into the `target` buffer. The `source` stream
	cursor is incremented by `count`.
]=]
function stream.copytobuffer(target: buffer, targetOffset: number, source: Stream, count: number)
	buffer.copy(target, targetOffset, source.b, source.o, count)
	source.o += count
end

--[=[
	@within stream

	Copy `count` bytes from the `source` buffer (optionally offset by `sourceOffset`) into the
	`target` stream. The `target` stream cursor is incremented by `count`.
]=]
function stream.copyfrombuffer(target: Stream, source: buffer, sourceOffset: number?, count: number)
	buffer.copy(target.b, target.o, source, sourceOffset, count)
	target.o += count
end

--[=[
	@within stream

	Moves the cursor relative to the beginning of the stream.
]=]
function stream.seek(s: Stream, offset: number)
	s.o = offset
	if s.o < 0 or s.o > s.l then
		error("seek out of bounds", 2)
	end
end

--[=[
	@within stream

	Moves the cursor backward relative to the end of the stream.
]=]
function stream.seekend(s: Stream, offset: number)
	s.o = s.l - offset
	if s.o < 0 or s.o > s.l then
		error("seek out of bounds", 2)
	end
end

--[=[
	@within stream

	Moves the cursor forward relative to the current cursor position.
]=]
function stream.seekforward(s: Stream, offset: number)
	s.o += offset
	if s.o < 0 or s.o > s.l then
		error("seek out of bounds", 2)
	end
end

--[=[
	@within stream

	Moves the cursor backward relative to the current cursor position.
]=]
function stream.seekbackward(s: Stream, offset: number)
	s.o -= offset
	if s.o < 0 or s.o > s.l then
		error("seek out of bounds", 2)
	end
end

--[=[
	@within stream

	Gets the backing buffer for the stream.
]=]
function stream.buffer(s: Stream): buffer
	return s.b
end

--[=[
	@within stream

	Returns the backing buffer as a string.
]=]
function stream.tostring(s: Stream): string
	return buffer.tostring(s.b)
end

--[=[
	@within stream

	Returns `true` if the cursor is at the end of the stream.
]=]
function stream.atend(s: Stream): boolean
	return s.o == s.l
end

-------------------------------------------------------------------------

return table.freeze(stream)
