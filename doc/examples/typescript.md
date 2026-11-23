# TypeScript with Vue {#typescript}

Vue’s reactivity package contains the TypeScript implementation of computed properties. Run its tests through the project’s own Vitest script, using the root development tools and dependencies locked in the workspace.

```sh
git clone --depth 1 --branch v3.5.22 https://github.com/vuejs/core vue
nix run github:drvlang/drvjs -- test -C vue -- --run packages/reactivity/__tests__/computed.spec.ts
```

This runs 49 tests, including cases for lazy evaluation and cache invalidation in a computed getter. drvjs reuses locked pnpm downloads and the installed dependency tree. Vitest handles the transformation and execution of the TypeScript files. [Vue test suite](https://github.com/vuejs/core/blob/5a8aa0b2ba575e098cbb63b396e9bcb751eb3a0f/packages/reactivity/__tests__/computed.spec.ts) · [drvjs workspace and flake options](https://github.com/drvlang/drvjs)
