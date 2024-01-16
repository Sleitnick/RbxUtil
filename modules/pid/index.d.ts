declare namespace PID {
	interface Constructor {
		/**
		 * Constructs a new PID.
		 *
		 * @param min Minimum output.
		 * @param max Maximum output.
		 * @param kp Proportional coefficient.
		 * @param ki Integral coefficient.
		 * @param kd Derivative coefficient.
		 */
		new (min: number, max: number, kp: number, ki: number, kd: number): PID;
	}
}

interface PID {
	/**
	 * POnE stands for "Proportional on Error".
	 *
	 * Set to `true` by default.
	 *
	 * - `true`: The PID applies the proportional calculation on the _error_.
	 * - `false`: The PID applies the proportional calculation on the _measurement_.
	 *
	 * Setting this value to `false` may help the PID move smoother and help
	 * eliminate overshoot.
	 */
	POnE: boolean;

	/**
	 * Calculates the new output based on the setpoint and input.
	 *
	 * @param setpoint The goal for the PID.
	 * @param input The current input.
	 * @param deltaTime Delta time.
	 * @returns The updated output.
	 */
	Calculate(setpoint: number, input: number, deltaTime: number): number;

	/**
	 * Resets the PID.
	 */
	Reset(): void;

	/**
	 * Creates a debug instance that can be used to tune the PID.
	 * This only works in Studio. This does nothing outside of Studio.
	 *
	 * @param name The name of the debug folder instance.
	 * @param parent The parent for the debug folder (defaults to Workspace).
	 */
	Debug(name: string, parent?: Instance): void;

	/**
	 * Destroys any debug instance created. `Destroy()` only needs
	 * to be called if `Debug()` was called.
	 */
	Destroy(): void;
}

/**
 * The PID class simulates a [PID controller](https://en.wikipedia.org/wiki/PID_controller).
 */
declare const PID: PID.Constructor;

export = PID;
