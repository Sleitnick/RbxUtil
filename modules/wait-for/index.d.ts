declare namespace WaitFor {
	interface Constructor {
		readonly Error: { Unparented: "Unparented"; ParentChanged: "ParentChanged" };

		Child: (parent: Instance, childName: string, timeout?: number) => Promise<Instance>;
		Children: (parent: Instance, childrenNames: string[], timeout?: number) => Promise<Instance[]>;
		Descendant: (parent: Instance, descendantName: string, timeout?: number) => Promise<Instance>;
		Descendants: (parent: Instance, descendantNames: string[], timeout?: number) => Promise<Instance[]>;
		PrimaryPart: (model: Model, timeout?: number) => Promise<BasePart>;
		ObjectValue: (objectValue: ObjectValue, timeout?: number) => Promise<Instance>;
		Custom: <T>(predicate: () => T | undefined, timeout?: number) => Promise<T>;
	}
}

declare const WaitFor: WaitFor.Constructor;

export = WaitFor;
