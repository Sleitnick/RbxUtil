declare namespace Quaternion {
	interface Constructor {
		/**
		 * Identity quaternion. Equal to `new Quaternion(0, 0, 0, 1)`.
		 */
		readonly identity: Quaternion;

		/**
		 * Constructs a new quaternion. Usually quaternions are not constructed
		 * directly through this constructor, but rather other helper constructors,
		 * such as `euler` and `axisAngle`.
		 */
		new (x: number, y: number, z: number, w: number): Quaternion;

		/**
		 * Constructs a quaternion from Euler angles (radians).
		 */
		euler: (x: number, y: number, z: number) => Quaternion;

		/**
		 * Constructs a quaternion from the axis and angle (radians).
		 */
		axisAngle: (axis: Vector3, angle: number) => Quaternion;

		/**
		 * Constructs a quaternion looking at `forward` direction. An
		 * optional `upwards` axis can be provided.
		 */
		lookRotation: (forward: Vector3, upwards?: Vector3) => Quaternion;

		/**
		 * Constructs a quaternion from the rotation components of the
		 * given CFrame.
		 */
		cframe: (cframe: CFrame) => Quaternion;
	}
}

interface Quaternion {
	readonly X: number;
	readonly Y: number;
	readonly Z: number;
	readonly W: number;

	/**
	 * Calculates the dot product between the two quaternions.
	 */
	Dot(other: Quaternion): number;

	/**
	 * Calculates the spherical interpolation between the two quaternions. The
	 * `alpha` parameter should be within the range of `[0, 1]`.
	 */
	Slerp(other: Quaternion, alpha: number): Quaternion;

	/**
	 * Calculates the angle in radians between the two quaternions.
	 */
	Angle(other: Quaternion): number;

	/**
	 * Constructs a new quaternion that rotates this quaternion towards the
	 * other quaternion, with a max rotation of `maxRadiansDelta`. Internally,
	 * this calls `Slerp` but limits the distance.
	 */
	RotateTowards(other: Quaternion, maxRadiansDelta: number): Quaternion;

	/**
	 * Creates a CFrame value from the quaternion. Quaternions only contain
	 * rotational information, so an optional `position` vector can be provided
	 * to set the position of the CFrame.
	 */
	ToCFrame(position?: Vector3): CFrame;

	/**
	 * Calculate the Euler angles (radians) that represent the quaternion.
	 */
	ToEulerAngles(): Vector3;

	/**
	 * Calculates the axis and angle (radians) representing the quaternion.
	 */
	ToAxisAngle(): LuaTuple<[axis: Vector3, angle: number]>;

	/**
	 * Returns the inverse of the quaternion.
	 */
	Inverse(): Quaternion;

	/**
	 * Returns the conjugate of the quaternion.
	 *
	 * This is equivalent to `new Quaternion(-X, -Y, -Z, W)`.
	 */
	Conjugate(): Quaternion;

	/**
	 * Returns the normalized representation of the quaternion.
	 */
	Normalize(): Quaternion;

	/**
	 * Calculates the magnitude of the quaternion.
	 */
	Magnitude(): number;

	/**
	 * Calculates the square magnitude of the quaternion.
	 */
	SqrMagnitude(): number;

	mul<T extends Quaternion | Vector3>(other: T): T;
}

declare const Quaternion: Quaternion.Constructor;

export = Quaternion;
