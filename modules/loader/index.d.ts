type PredicateFn = (module: ModuleScript) => boolean;
type Modules = { [key: string]: unknown };

declare namespace Loader {
	interface Constructor {
		LoadChildren: (parent: Instance, predicate?: PredicateFn) => Modules;
		LoadDescendants: (parent: Instance, predicate?: PredicateFn) => Modules;
		MatchesName: (matchName: string) => (module: ModuleScript) => boolean;
		SpawnAll: (loadedModules: Modules, methodName: string) => void;
	}
}

declare const Loader: Loader.Constructor;

export = Loader;
