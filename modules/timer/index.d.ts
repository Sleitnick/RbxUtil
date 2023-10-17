declare namespace Timer {
	interface Constructor {
		/**
		 * Creates a new timer.
		 *
		 * @param interval The interval for the timer tick.
		 */
		new (interval: number): Timer;

		/**
		 * Creates a simple-to-use timer without having to interface
		 * with the rest of the class.
		 * @param interval The interval for the timer tick.
		 * @param callback The tick callback.
		 * @param startNow Whether or not it should tick immediately (defaults to `false`).
		 * @param updateSignal The update signal (defaults to `RunService.Heartbeat`).
		 * @param timeFn The time function (defaults to `time`).
		 */
		Simple(
			interval: number,
			callback: () => void,
			startNow?: boolean,
			updateSignal?: RBXScriptSignal,
			timeFn?: () => number,
		): Timer;
	}
}

interface Timer {
	/** The tick interval. */
	readonly Interval: number;

	/** The signal which is fired every tick. */
	readonly Tick: RBXScriptSignal;

	/** The function used to grab the current time. */
	TimeFunction: () => number;

	/** The signal used to update the timer. */
	UpdateSignal: RBXScriptSignal;

	/**
	 * Allow the timer to drift (`true` by default). A timer
	 * that drifts is much more simple. If the timer must keep
	 * from drifting, more logic must be performed.
	 */
	AllowDrift: boolean;

	/**
	 * Starts the timer. If already running, this does nothing.
	 */
	Start(): void;

	/**
	 * Starts the timer and ticks immediately. If already running,
	 * this does nothing.
	 */
	StartNow(): void;

	/**
	 * Stops the timer. If already stopped, this does nothing.
	 */
	Stop(): void;

	/**
	 * Returns `true` if the timer has been started.
	 */
	IsRunning(): boolean;

	/**
	 * Stops the timer and disconnects any connections to the `Tick` signal.
	 */
	Destroy(): void;
}

declare const Timer: Timer.Constructor;

export = Timer;
