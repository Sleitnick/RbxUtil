declare namespace Option {
	interface Constructor {
		readonly None: Option<never>;

		Some: <T>(value: NonNullable<T>) => Option<T>;
		Wrap: <T>(value: T) => Option<T>;
		Is: (value: unknown) => boolean;
		Assert: (value: unknown) => void;
		Deserialize: <T>(data: SerializedOption<T>) => Option<T>;
	}

	interface SerializedOption<T> {
		ClassName: "Option";
		Value?: T;
	}

	interface Match<T, V> {
		Some: (value: T) => V;
		None: () => V;
	}
}

interface Option<T> {
	Serialize(): Option.SerializedOption<T>;
	Match<V>(match: Option.Match<T, V>): V;
	IsSome(): boolean;
	IsNone(): boolean;
	Expect(msg: string): T;
	ExpectNone(msg: string): void;
	Unwrap(): T;
	UnwrapOr(defaultValue: T): T;
	UnwrapOrElse(defaultFn: () => T): T;
	And<O>(optionB: Option<O>): Option<O>;
	AndThen<V>(andThenFn: (value: T) => V): Option<V>;
	Or<O>(optionB: Option<O>): Option<T> | Option<O>;
	OrElse<V>(orElseFn: (value: T) => V): Option<V>;
	XOr<O>(optionB: Option<O>): Option<T> | Option<O>;
	Filter(predicate: (value: T) => boolean): Option<T>;
	Contains(value: T): boolean;
}

declare const Option: Option.Constructor;

export = Option;
