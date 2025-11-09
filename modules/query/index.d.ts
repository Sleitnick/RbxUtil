/**
 * Adds helpful functions that wrap
 * [`Instance:QueryDescendants()`](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants).
 */
interface Query {
	/**
	 * Equivalent to [`parent.QueryDescendants(selector)`](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants).
	 */
	all: (parent: Instance, selector: string) => Instance[];

	/**
	 * Returns the query result, filtered by the `filter` function. Ideally, most of
	 * the filtering should be done with the selector itself. However, if the selector
	 * is not enough, this function can be used to further filter the results.
	 */
	filter: (parent: Instance, selector: string, filter: (instance: Instance) => boolean) => Instance[];

	/**
	 * Returns the query result mapped by the `map` function.
	 */
	map: <T>(parent: Instance, selector: string, map: (instance: Instance) => T) => Instance[];

	/**
	 * Returns the first item from the query. Might be `nil` if the query returns
	 * nothing.
	 *
	 * This is equivalent to `parent.QueryDescendants(selector)[1]`.
	 */
	first: (parent: Instance, selector: string) => Instance | undefined;

	/**
	 * Asserts that the query returns exactly one instance. The instance is returned.
	 * This is useful when attempting to find an exact match of an instance that
	 * must exist.
 	 *
	 * If the result returns zero or more than one result, an error is thrown.
	 */
	one: (parent: Instance, selector: string) => Instance;
}

declare const Query: Query;

export = Query;
