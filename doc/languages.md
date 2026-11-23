# Language builders {#languages}

Each drvlang builder provides `build`, `test`, and `run`, plus flake packages, checks, and apps. Use the native dependency files shown below. Nix derives fetches from their checksums or immutable revisions, so you can update dependencies without also editing a Nix hash.

| Builder | Native dependency input | Worked example |
| --- | --- | --- |
| [drvgo](https://github.com/drvlang/drvgo) | Go modules, `go.mod` and `go.sum` | [Replit UPM](#go) |
| [drvjs](https://github.com/drvlang/drvjs) | pnpm workspaces, `pnpm-lock.yaml` versions 9, 12, or experimental 13 | [JavaScript](#javascript) · [TypeScript](#typescript) |
| [drvpy](https://github.com/drvlang/drvpy) | uv, version 1 `uv.lock` | [Flask](#python) |
| [drvrb](https://github.com/drvlang/drvrb) | Bundler, checksummed `Gemfile.lock` | [Ruby GraphQL](#ruby) |
| [drvrust](https://github.com/drvlang/drvrust) | Cargo, version 4 `Cargo.lock` | [hexyl](#rust) |
| [drvjava](https://github.com/drvlang/drvjava) | Maven artifacts in a version 3 `rules_jvm_external` lock | [IndexJar](#java) |
| [drvnet](https://github.com/drvlang/drvnet) | NuGet, version 1 or 2 `packages.lock.json` | [Dev Proxy](#dotnet) |
| [drvc](https://github.com/drvlang/drvc) | Meson, including hashed source and patch archives in `.wrap` files | [mmdoc](#c) |
| [drvcpp](https://github.com/drvlang/drvcpp) | Meson, including hashed source and patch archives in `.wrap` files | [OpenH264](#cpp) |

## Run the examples

Use a Nix version with dynamic derivation support. Enable these settings in `nix.conf` on the client and builder. Restart the Nix daemon after changing its configuration.

```ini
extra-experimental-features = nix-command flakes ca-derivations dynamic-derivations recursive-nix
extra-system-features = recursive-nix ca-derivations
```

The examples target Linux on x86-64 or ARM64. drvgo and drvrb also support Apple Silicon macOS, and drvc supports both Intel and Apple Silicon macOS. Check each builder’s README for toolchains and project-specific options. For several programs in one repository, expose named outputs with `mkMonorepoFlake`. [Monorepo example](#monorepos)
