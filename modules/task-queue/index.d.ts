declare namespace TaskQueue {
	interface Constructor {
		new <T>(onFlush: (items: T[]) => void): TaskQueue<T>;
	}
}

interface TaskQueue<T> {
	/**
	 * Add an item to the queue.
	 */
	Add(item: T): void;

	/**
	 * Clears items in the queue (except for items currently being flushed,
	 * which would only occur if the flushing function yielded).
	 */
	Clear(): void;

	/**
	 * Alias for `Clear()`.
	 */
	Destroy(): void;
}

declare const TaskQueue: TaskQueue.Constructor;

export = TaskQueue;
