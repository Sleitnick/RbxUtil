interface Stream {}

interface stream {
	/** Creates a stream. */
	create: (size: number) => Stream;

	/** Creates a stream from an existing buffer. */
	frombuffer: (buf: buffer) => Stream;

	/** Creates a stream from a buffer created with the given string. */
	fromstring: (str: string) => Stream;

	readu8: (s: Stream) => number;
	readi8: (s: Stream) => number;
	readu16: (s: Stream) => number;
	readi16: (s: Stream) => number;
	readu32: (s: Stream) => number;
	readi32: (s: Stream) => number;
	readf32: (s: Stream) => number;
	readf64: (s: Stream) => number;
	readstring: (s: Stream, count: number) => string;
	readlstring: (s: Stream) => string;
	readvectorf32: (s: Stream) => vector;
	readvectoru32: (s: Stream) => vector;
	readvectori32: (s: Stream) => vector;
	readvectoru16: (s: Stream) => vector;
	readvectori16: (s: Stream) => vector;
	readvectoru8: (s: Stream) => vector;
	readvectori8: (s: Stream) => vector;

	writeu8: (s: Stream, n: number) => void;
	writei8: (s: Stream, n: number) => void;
	writeu16: (s: Stream, n: number) => void;
	writei16: (s: Stream, n: number) => void;
	writeu32: (s: Stream, n: number) => void;
	writei32: (s: Stream, n: number) => void;
	writef32: (s: Stream, n: number) => void;
	writef64: (s: Stream, n: number) => void;
	writestring: (s: Stream, str: string, count?: number) => void;
	writelstring: (s: Stream, str: string, count?: number) => void;
	writevectorf32: (s: Stream, v: vector) => void;
	writevectoru32: (s: Stream, v: vector) => void;
	writevectori32: (s: Stream, v: vector) => void;
	writevectoru16: (s: Stream, v: vector) => void;
	writevectori16: (s: Stream, v: vector) => void;
	writevectoru8: (s: Stream, v: vector) => void;
	writevectori8: (s: Stream, v: vector) => void;

	/** Get the length of the backing buffer. */
	len: (s: Stream) => number;

	/** Get the cursor position. */
	pos: (s: Stream) => number;

	/** Copy `count` bytes from `source` into `target`. */
	copy: (target: Stream, source: Stream, count: number) => void;

	/** Copy `count` bytes from the `source` stream into the `target` buffer. */
	copytobuffer: (target: buffer, targetOffset: number, source: Stream, count: number) => void;
	
	/** Copy `count` bytes from the `source` buffer into the `target` stream. */
	copyfrombuffer: (target: Stream, source: buffer, sourceOffset: number | undefined, count: number) => void;

	/** Set the cursor relative to the beginning of the buffer. */
	seek: (s: Stream, offset: number) => void;

	/** Set the cursor backward relative to the end of the buffer. */
	seekend: (s: Stream, offset: number) => void;

	/** Offset the cursor forward from its current position. */
	seekforward: (s: Stream, offset: number) => void;

	/** Offset the cursor backward from its current position. */
	seekbackward: (s: Stream, offset: number) => void;

	/** Gets the string of the backing buffer. */
	tostring: (s: Stream) => string;

	/** Get the backing buffer. */
	buffer: (s: Stream) => buffer;

	/** Returns `true` if the cursor is at the end of the stream. */
	atend: (s: Stream) => boolean;
}

declare const stream: stream;

export = stream;
