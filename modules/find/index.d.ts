/**
 * Find an instance in the data model hierarchy, otherwise throw an error.
 *
 * ```ts
 * const part = find<BasePart>(Workspace, "Some", "Model", "Part");
 * ```
 *
 * Note that the generic type is not a runtime-enforced type-check. A custom
 * assertion is needed if you desire to enforce the type:
 * ```ts
 * const folder = find<Folder>(ReplicatedStorage, "Somewhere", "MyFolder");
 * assert(folder.IsA("Folder"));
 * ```
 *
 * @param parent The parent where the search begins.
 * @param path The name of each instance, where the last one is the returned instance.
 */
declare function find<T extends Instance = Instance>(parent: Instance, ...path: string[]): T;

export = find;
