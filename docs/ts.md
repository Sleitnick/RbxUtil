---
sidebar_position: 2
---

# TypeScript

Some modules can be used in [roblox-ts](https://roblox-ts.com/). These modules live within their own `@rbxutil` NPM org.

For a full listing of the available NPM packages, visit the [RbxUtil NPM org](https://www.npmjs.com/org/rbxutil).

## Installation

Installing modules works like any other roblox-ts package, except that the prefix will be `@rbxutil`. For instance, to install the quaternion library, run the following command:

```bash
$ npm install @rbxutil/quaternion
```

## Configuration

In order for modules from `@rbxutil` to work, two changes will need to be made:
1. Add the modules to the Rojo project file
1. Expose the types to TypeScript

### Rojo Project

In the `default.project.json` file, add the `@rbxutil` directory into ReplicatedStorage, right alongside `@rbxts`:

```json
"node_modules": {
	"$className": "Folder",
	"@rbxts": {
		"$path": "node_modules/@rbxts"
	},
	"@rbxutil": {
		"$path": "node_modules/@rbxutil"
	}
}
```

### Types Configuration

In the `tsconfig.json` file, add the `@rbxutil` directory to the types list. The `@rbxts` org should already be there:

```json
"typeRoots": ["node_modules/@rbxts", "node_modules/@rbxutil"]
```

## Different Org

In order to avoid naming conflicts and namespace cluttering, RbxUtil modules will be placed in their own NPM org (`@rbxutil`). This has been done out of respect for roblox-ts package developers and to allow RbxUtil to grow unbounded by the current default org packages.

For example, there is already a Signal package within the default `@rbxts` org. Also, RbxUtil has many generic names, such as Log and Shake. While these are named to convey their meaning easily, it is best to not clutter the `@rbxts` org with a vast array of such names from a single repository. This naming issue is not an issue for Wally, as Wally uses the author's name as the namespace.

## Contributing

If you find any types that are incorrect, missing, or broken, please feel free to open up a GitHub Issue and/or pull request to address and fix these issues.
