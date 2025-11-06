declare namespace Spring {
	interface Constructor {
		/** Constructs a new spring. */
		new <T extends Vector2 | Vector3 | CFrame | number>(
			initial: T,
			smoothTime: number,
			maxSpeed?: number,
		): Spring<T>;
	}
}

interface Spring<T extends Vector2 | Vector3 | CFrame | number> {
	/** The current value of the spring. */
	Current: T;

	/** The target value of the spring. */
	Target: T;

	/** The spring's current velocity. */
	Velocity: T;

	/** Approximately how many seconds it will take to reach the target. */
	SmoothTime: number;

	/** Maximum allowed speed of the spring. */
	MaxSpeed: number;

	/** Updates the spring. */
	Update(deltaTime: number): T;

	/** Impulses the spring. */
	Impulse(force: T): void;

	/** Resets the spring. */
	Reset(): void;
}

declare const Spring: Spring.Constructor;

export = Spring;
