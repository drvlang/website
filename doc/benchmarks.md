# CI Benchmarks {#benchmarks}

CIBench measures how long a CI worker takes to evaluate, build, and verify a real package and its behavior check under controlled CPU, memory, and binary-cache limits. Each workload runs a drvlang builder alongside the conventional Nixpkgs builder for the same language using the same pinned Nixpkgs and Go toolchain.

## Go (`drvgo` vs. `buildGoModule`)

The Go workload builds a small command that depends on `github.com/google/uuid` and runs a check that executes the installed binary and verifies its output.

- **Original project**: builds the client against `github.com/google/uuid` v1.5.0 and checks its printed UUID version.
- **Source edit**: modifies `main.go` and the expected output without changing `go.mod` or `go.sum`.
- **Dependency update**: upgrades `github.com/google/uuid` from v1.5.0 to v1.6.0 in `go.mod` and `go.sum`. Because `buildGoModule` requires a separate Nix hash, it receives the matching updated `vendorHash` outside the timed job; `drvgo` reads the updated `go.sum` directly.

### What each test case measures

Every case runs in an independent chroot Nix store with strict sandboxing and import-from-derivation disabled. A **baseline** is the first successful cold build of that implementation, including its intermediate outputs, derivations, and content-addressed build traces. Edited runs can reuse baseline outputs, and their results are never published back to the cache.

| Test case | Project version | Local store at start | Project cache at start | What it models in CI |
| --- | --- | --- | --- | --- |
| `cold` | original | empty | empty | First build of a repository with no prior project cache (stock NixOS packages may still come from the upstream cache). |
| `remote-warm` | original | empty | baseline | A fresh ephemeral CI runner restoring an unchanged commit from the shared remote binary cache. |
| `local-warm` | original | baseline | empty | A persistent runner or developer machine re-evaluating and checking an unchanged commit whose outputs are already in the local Nix store. |
| `edit-remote` | source edit | empty | baseline | A fresh ephemeral CI runner building a pull request that edits application code while reusing cached dependencies from the remote binary cache. |
| `edit-local` | source edit | baseline | empty | A warm local runner or developer machine rebuilding after an application source edit. |
| `dependency-remote` | dependency update | empty | baseline | A fresh ephemeral CI runner building a lockfile bump (`uuid` 1.5.0 → 1.6.0) while reusing unaffected cached work from the remote cache. |
| `dependency-local` | dependency update | baseline | empty | A warm local runner or developer machine rebuilding after a dependency update. |

### Results

Optimizing `drvgo` from `f003540` to `6de29ff` sped up all seven cases and cut remote binary-cache downloads nearly in half. On all four incremental CI cases (`edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`), `drvgo` is now 1.8× to 2.9× faster than Nixpkgs `buildGoModule`.

| Test case | `drvgo` `f003540` (s) | `drvgo` `6de29ff` (s) | `buildGoModule` (s) | `drvgo` cache download (before → after) | `drvgo` recipes built (before → after) |
| --- | ---: | ---: | ---: | ---: | ---: |
| `cold` | 84.36 | 21.61 | 8.30 | 0.0 → 0.0 MiB | 139 → 136 |
| `remote-warm` | 13.20 | 3.85 | 1.10 | 407.3 → 214.7 MiB | 0 → 0 |
| `local-warm` | 1.23 | 0.79 | 0.74 | 0.0 → 0.0 MiB | 0 → 0 |
| `edit-remote` | 17.68 | 5.21 | 10.18 | 403.2 → 210.6 MiB | 5 → 5 |
| `edit-local` | 4.74 | 2.37 | 6.94 | 0.0 → 0.0 MiB | 5 → 5 |
| `dependency-remote` | 57.85 | 5.39 | 9.86 | 403.2 → 210.3 MiB | 14 → 13 |
| `dependency-local` | 43.59 | 3.26 | 7.19 | 0.0 → 0.0 MiB | 14 → 13 |

Times are medians of alternating trials on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, Go 1.26.5, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): two trials for `f003540`, three for `6de29ff`, and five for the shared `buildGoModule` comparator, with no competing host workloads.

### Why `drvgo` got faster

- **Direct Nix daemon planners**: `drvgo` now registers module files, package sources, and ATerm `.drv` graphs directly over the recursive Nix daemon socket using a persistent concurrent connection pool instead of spawning `nix-instantiate` and `nix-store`. This removed `pkgs.nix` (~35 MiB) and Nixpkgs evaluation from the planners.
- **Smaller recursive sandbox mount tables**: Passing compact realized worker toolchains directly to the native Go planner cut recursive sandbox bind-mounts from ~890 to ~50, speeding up every daemon registration and letting helper binaries compile in parallel on cold builds.
- **No duplicate GCC copy and compact toolchain slices**: Removed a 264 MiB duplicate GCC copy (~81 MiB compressed download on every remote CI job), kept pinned static toolchain slices input-addressed with substitution enabled while keeping all generated packages, units, assemblies, checks, and planners floating content-addressed, and passed the compact planning toolchain to the module cache builder.
- **Pure-Go worker build**: Built `drvgo-worker` directly with `pkgs.go` without pulling `stdenv` or running unit tests on consumer cold builds (unit tests run in `checks.<system>.drvgo-tests`).

### Where `buildGoModule` is still faster

On `cold` and `remote-warm`, `buildGoModule` remains faster on this small single-package fixture. `drvgo` builds 136 package-granular derivations on a cold build (including individual Go standard-library packages so edits and dependency updates can reuse them), and Nix 2.35 currently downloads build-time inputs of floating content-addressed derivations before looking up cached realisations on `remote-warm`. Once any source file or dependency changes, package-granular reuse lets `drvgo` rebuild only the affected Go package(s) and check rather than re-vendoring and recompiling the entire module.

[Detailed Go report](https://github.com/drvlang/drvgo/blob/6de29ff449b58072bb2b27909a44c3debad755d4/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvgo/blob/6de29ff449b58072bb2b27909a44c3debad755d4/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench)
