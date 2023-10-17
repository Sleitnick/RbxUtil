declare namespace Shake {
	interface Constructor {
		new (): Shake;

		InverseSquare: (shake: Vector3, distance: number) => Vector3;
		NextRenderName: () => string;
	}
}

type UpdateReturn = [position: Vector3, rotation: Vector3, done: boolean];

interface Shake {
	Amplitude: number;
	Frequency: number;
	FadeInTime: number;
	FadeOutTime: number;
	SustainTime: number;
	Sustain: boolean;
	PositionInfluence: Vector3;
	RotationInfluence: Vector3;
	TimeFunction: () => number;

	Start(): void;
	Stop(): void;
	IsShaking(): boolean;
	StopSustain(): void;
	Update(): LuaTuple<UpdateReturn>;
	OnSignal(signal: RBXScriptSignal, callback: (...args: UpdateReturn) => void): RBXScriptConnection;
	BindToRenderStep(name: string, priority: number, callback: (...args: UpdateReturn) => void): void;
	Clone(): Shake;
	Destroy(): void;
}

declare const Shake: Shake.Constructor;

export = Shake;
