type SignalParams<T> = Parameters<
	T extends unknown[] ? (...args: T) => never : T extends unknown ? (arg: T) => never : () => never
>;
type SignalCallback<T> = (...args: SignalParams<T>) => unknown;
type SignalWait<T> = T extends unknown[] ? LuaTuple<T> : T;

type RBXScriptSignalType<T> = T extends unknown[]
	? RBXScriptSignal<(...args: T) => void>
	: T extends unknown
	? RBXScriptSignal<(arg: T) => void>
	: RBXScriptSignal;

declare namespace Signal {
	interface Constructor {
		/**
		 * Constructs a new Signal.
		 */
		new <T extends unknown[] | unknown>(): Signal<T>;

		/**
		 * Creates a new Signal that wraps around a native Roblox signal. The benefit
		 * of doing this is the ability to hook into Roblox signals and easily manage
		 * them in once place.
		 */
		Wrap: <T extends unknown[] | unknown>(rbxScriptSignal: RBXScriptSignalType<T>) => Signal<T>;

		/**
		 * Returns `true` if the given object is a Signal.
		 */
		Is: <T>(obj: T) => boolean;
	}

	export interface Connection {
		/**
		 * If `true`, the connection is still connected. This field is read-only.
		 *
		 * To disconnect a connection, call the connection's `Disconnect()` method.
		 */
		readonly Connected: boolean;

		/**
		 * Disconnect the connection.
		 */
		Disconnect(): void;

		/**
		 * Alias for `Disconnect()`.
		 */
		Destroy(): void;
	}
}

interface Signal<T extends unknown[] | unknown> {
	/**
	 * Connects a callback function to the signal. This callback function
	 * will be called any time the signal is fired.
	 */
	Connect(callback: SignalCallback<T>): Signal.Connection;

	/**
	 * Connects a callback function to the signal which will fire only
	 * once and then automatically disconnect itself.
	 */
	Once(callback: SignalCallback<T>): Signal.Connection;

	/**
	 * Fires the signal.
	 */
	Fire(...args: SignalParams<T>): void;

	/**
	 * Fires the signal using `task.defer` internally. This should only be
	 * used if `task.defer` is necessary, as the normal `Fire` method optimizes
	 * for thread reuse internally.
	 */
	FireDeferred(...args: SignalParams<T>): void;

	/**
	 * Yields the current thread until the signal fires. The arguments fired are
	 * returned.
	 */
	Wait(): SignalWait<T>;

	/**
	 * Disconnects all connections to the signal.
	 */
	DisconnectAll(): void;

	/**
	 * Destroys the signal. This is an alias for `Disconnect()`.
	 */
	Destroy(): void;
}

/**
 * Signal class.
 */
declare const Signal: Signal.Constructor;

export = Signal;
