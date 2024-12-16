--!native

local BufferReader = require(script.BufferReader)
local BufferWriter = require(script.BufferWriter)
local Types = require(script.Types)

--[=[
	@class BufferUtil
]=]

--[=[
	@within BufferUtil
	@function reader
	@param buf buffer | string
	@return BufferReader

	Creates a BufferReader. The reader can be constructed from either
	a string or a `buffer` object.

	```lua
	local reader = BufferUtil.reader()
	```
]=]

--[=[
	@within BufferUtil
	@function writer
	@param initialCapacity number?
	@return BufferWriter

	Creates a zero-initialized BufferWriter. An initial capacity can
	optionally be set, and is defaulted to `0`.

	```lua
	local writer = BufferUtil.writer()
	```
]=]

export type BufferReader = Types.BufferReader
export type BufferWriter = Types.BufferWriter

return {
	reader = BufferReader.new,
	writer = BufferWriter.new,
}
