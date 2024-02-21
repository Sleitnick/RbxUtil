declare namespace PID {
	interface Constructor {
		/**
		 * Constructs a new PID.
		 *
		 * @param min Minimum output.
		 * @param max Maximum output.
		 * @param kp Proportional gain coefficient.
		 * @param ki Integral gain coefficient.
		 * @param kd Derivative gain coefficient.
		 */
		new (min: number, max: number, kp: number, ki: number, kd: number): PID;
	}
}

interface PID {
	/**
	 * Calculates the new output based on the setpoint and input.
	 *
	 * @param setpoint The goal for the PID.
	 * @param processVariable The measured value of the system to compare against the setpoint.
	 * @param deltaTime Delta time.
	 * @returns The updated output.
	 */
	Calculate(setpoint: number, processVariable: number, deltaTime: number): number;

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
