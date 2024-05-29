interface ConnectionLike {
	Disconnect(this: ConnectionLike): void;
}

type Trackable =
	| Instance
	| RBXScriptConnection
	| ConnectionLike
	| Promise<unknown>
	| thread
	| ((...args: unknown[]) => unknown)
	| { destroy: () => void }
	| { disconnect: () => void }
	| { Destroy: () => void }
	| { Disconnect: () => void };

declare namespace Trove {
	interface Constructor {
		new (): Trove;
	}
}

interface Trove {
	Extend(): Trove;
	Clone<T extends Instance>(): T;
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	Construct<T extends { new (...args: any[]): InstanceType<T> }>(
		cls: T,
		...args: ConstructorParameters<T>
	): InstanceType<T>;
	Connect<T extends Callback = Callback>(signal: RBXScriptSignal<T>, fn: T): RBXScriptConnection;
	BindToRenderStep(name: string, priority: number, fn: (dt: number) => void): void;
	AddPromise<T>(promise: Promise<T>): Promise<T>;
	Add<T extends Trackable>(object: T, cleanupMethod?: string): T;
	Remove<T extends Trackable>(object: T): boolean;
	AttachToInstance(instance: Instance): RBXScriptConnection;
	Clean(): void;
	WrapClean(): () => void;
	Destroy(): void;
}

declare const Trove: Trove.Constructor;

export = Trove;
