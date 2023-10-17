---
sidebar_position: 2
---

# TypeScript

Some modules can be used in [roblox-ts](https://roblox-ts.com/). These modules live within their own `@rbxutil` NPM org.

For a full listing of the available NPM packages, visit the [RbxUtil NPM org](https://www.npmjs.com/settings/rbxutil/packages).

## Installation

Installing modules works like any other roblox-ts package, except that the suffix will be `@rbxutil`. For instance, to install the quaternion library, run the following command:

```bash
$ npm install @rbxutil/quaternion
```

## Configuration

In the `tsconfig.json` file, add the `@rbxutil` directory to the types list. The `@rbxts` org should already be there:

```json
"typeRoots": ["node_modules/@rbxts", "node_modules/@rbxutil"]
```
