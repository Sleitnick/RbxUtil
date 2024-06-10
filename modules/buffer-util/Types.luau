export type DataTypes =
	BrickColor
	| CFrame
	| Color3
	| DateTime
	| Ray
	| Rect
	| Region3
	| Region3int16
	| UDim
	| UDim2
	| Vector2
	| Vector3
	| Vector2int16
	| Vector3int16

export type BufferReader = {
	ReadInt8: (self: BufferReader) -> number,
	ReadUInt8: (self: BufferReader) -> number,
	ReadInt16: (self: BufferReader) -> number,
	ReadUInt16: (self: BufferReader) -> number,
	ReadInt32: (self: BufferReader) -> number,
	ReadUInt32: (self: BufferReader) -> number,
	ReadFloat32: (self: BufferReader) -> number,
	ReadFloat64: (self: BufferReader) -> number,
	ReadBool: (self: BufferReader) -> boolean,
	ReadString: (self: BufferReader) -> string,
	ReadStringRaw: (self: BufferReader, length: number) -> string,
	ReadDataType: <T>(self: BufferReader, dataType: { new: (...any) -> T }) -> T,
	GetSize: (self: BufferReader) -> number,
	ResetCursor: (self: BufferReader) -> (),
	SetCursor: (self: BufferReader, cursorPosition: number) -> (),
	GetCursor: (self: BufferReader) -> number,
	GetBuffer: (self: BufferReader) -> buffer,
}

export type BufferWriter = {
	WriteInt8: (self: BufferWriter, int8: number) -> (),
	WriteUInt8: (self: BufferWriter, uint8: number) -> (),
	WriteInt16: (self: BufferWriter, int16: number) -> (),
	WriteUInt16: (self: BufferWriter, uint16: number) -> (),
	WriteInt32: (self: BufferWriter, int32: number) -> (),
	WriteUInt32: (self: BufferWriter, uint32: number) -> (),
	WriteFloat32: (self: BufferWriter, f32: number) -> (),
	WriteFloat64: (self: BufferWriter, f64: number) -> (),
	WriteBool: (self: BufferWriter, bool: boolean) -> (),
	WriteString: (self: BufferWriter, str: string, length: number?) -> (),
	WriteStringRaw: (self: BufferWriter, str: string, length: number?) -> (),
	WriteDataType: (self: BufferWriter, data: DataTypes) -> (),
	GetSize: (self: BufferWriter) -> number,
	GetCapacity: (self: BufferWriter) -> number,
	ResetCursor: (self: BufferWriter) -> (),
	SetCursor: (self: BufferWriter, cursorPosition: number) -> (),
	GetCursor: (self: BufferWriter) -> number,
	Shrink: (self: BufferWriter) -> (),
	GetBuffer: (self: BufferWriter) -> buffer,
	ToString: (self: BufferWriter) -> string,
}

return nil
