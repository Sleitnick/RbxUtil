declare namespace BufferUtil {
	interface Util {
		/** Create a BufferReader from the given `buffer` or string. */
		reader: (buf: buffer | string | BufferWriter) => BufferReader;

		/** Create a zero-initialized BufferWriter with an optional initial byte capacity. */
		writer: (initialCapacity?: number) => BufferWriter;
	}

	interface BufferReader {
		/** Read a signed 8-bit integer from the buffer. */
		ReadInt8(): number;

		/** Read an unsigned 8-bit integer from the buffer. */
		ReadUInt8(): number;

		/** Read a signed 16-bit integer from the buffer. */
		ReadInt16(): number;

		/** Read an unsigned 16-bit integer from the buffer. */
		ReadUInt16(): number;

		/** Read a signed 32-bit integer from the buffer. */
		ReadInt32(): number;

		/** Read an unsigned 32-bit integer from the buffer. */
		ReadUInt32(): number;

		/** Read a 32-bit single-precision float from the buffer. */
		ReadFloat32(): number;

		/** Read a 64-bit double-precision float from the buffer. */
		ReadFloat64(): number;

		/** Read a string from the buffer. */
		ReadString(): string;

		/** Read a raw string from the buffer. */
		ReadStringRaw(length: number): string;

		/** Returns the position of the cursor. */
		GetCursor(): number;

		/** Sets the position of the cursor. */
		SetCursor(position: number): void;

		/** Resets the position of the cursor. */
		ResetCursor(): void;

		/** Returns the size of the buffer. */
		GetSize(): number;

		/** Returns the `buffer` object. */
		GetBuffer(): buffer;
	}

	interface BufferWriter {
		/** Write a signed 8-bit integer to the buffer. */
		WriteInt8(int8: number): void;

		/** Write an unsigned 8-bit integer to the buffer. */
		WriteUInt8(uint8: number): void;

		/** Write a signed 16-bit integer to the buffer. */
		WriteInt16(int16: number): void;

		/** Write an unsigned 16-bit integer to the buffer. */
		WriteUInt16(uint16: number): void;

		/** Write a signed 32-bit integer to the buffer. */
		WriteInt32(int32: number): void;

		/** Write an unsigned 32-bit integer to the buffer. */
		WriteUInt32(uint32: number): void;

		/** Write a 32-bit single-precision float to the buffer. */
		WriteFloat32(f32: number): void;

		/** Write a 64-bit double-precision float to the buffer. */
		WriteFloat64(f64: number): void;

		/** Write a string to the buffer, with an optional `length` of bytes taken from the string. */
		WriteString(str: string, length?: number): void;

		/** Write a raw string to the buffer, with an optional `length` of bytes taken from the string. */
		WriteStringRaw(str: string, length?: number): void;

		/** Shrinks the capacity of the buffer to the current data size. */
		Shrink(): void;

		/**
		 * 	Returns the current data size of the buffer. This is _not_ necessarily
		 *  equal to the capacity of the buffer.
		 */
		GetSize(): number;

		/**
		 * Returns the current capacity of the buffer. This is the length of the
		 * internal buffer, which is usually not the same as the length of the stored
		 * data.
		 *
		 * The buffer capacity automatically grows as data is added.
		 */
		GetCapacity(): number;

		/** Returns the `buffer` object. */
		GetBuffer(): buffer;

		/** Sets the position of the cursor. */
		SetCursor(position: number): void;

		/** Gets the position of the cursor. */
		GetCursor(): number;

		/** Resets the position of the cursor. */
		ResetCursor(): number;

		/** Returns the string version of the internal buffer. */
		ToString(): string;
	}
}

declare const BufferUtil: BufferUtil.Util;

export = BufferUtil;
