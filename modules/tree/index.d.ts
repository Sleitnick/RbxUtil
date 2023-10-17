declare namespace Tree {
	interface Constructor {
		Find(parent: Instance, path: string): Instance;
		Find<T extends keyof Instances>(parent: Instance, path: string, assertIsA: T): Instances[T];

		Await(parent: Instance, path: string, timeout?: number): Instance;
		Await<T extends keyof Instances>(parent: Instance, path: string, timeout: number, assertIsA: T): Instances[T];

		Exists(parent: Instance, path: string, assertIsA?: keyof Instances): boolean;
	}
}

declare const Tree: Tree.Constructor;

export = Tree;
