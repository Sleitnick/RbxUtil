declare namespace Sequent {
	interface Constructor {
		new <T>(cancellable?: boolean): Sequent<T>;
	}

	interface SequentEvent<T> {
		readonly Value: T;
		readonly Cancellable: boolean;
		Cancel(): void;
	}

	interface SequentConnection {
		readonly Connected: boolean;
		Disconnect(): void;
	}
}

interface Sequent<T> {
	Fire(value: T): void;
	Connect(callback: (event: Sequent.SequentEvent<T>) => void): Sequent.SequentConnection;
	Once(callback: (event: Sequent.SequentEvent<T>) => void): Sequent.SequentConnection;
	Cancel(): void;
	Destroy(): void;
}

declare const Sequent: Sequent.Constructor;

export = Sequent;
