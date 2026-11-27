# CI Benchmarks {#benchmarks}

CIBench measures how long a CI worker takes to evaluate, build, and verify a real package and its behavior check under controlled CPU, memory, and binary-cache limits. Each workload runs a drvlang builder alongside the conventional Nixpkgs builder for the same language using the same pinned Nixpkgs and toolchain.

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

On all four incremental CI cases (`edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`), `drvgo` is 1.8× to 2.9× faster than Nixpkgs `buildGoModule`.

| Test case | `drvgo` (s) | `buildGoModule` (s) | `drvgo` cache download (MiB) | `buildGoModule` cache download (MiB) | `drvgo` recipes built | `buildGoModule` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 21.61 | 8.30 | 0.0 | 0.0 | 136 | 3 |
| `remote-warm` | 3.85 | 1.10 | 214.7 | 12.9 | 0 | 0 |
| `local-warm` | 0.79 | 0.74 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 5.21 | 10.18 | 210.6 | 205.1 | 5 | 2 |
| `edit-local` | 2.37 | 6.94 | 0.0 | 0.0 | 5 | 2 |
| `dependency-remote` | 5.39 | 9.86 | 210.3 | 246.5 | 13 | 3 |
| `dependency-local` | 3.26 | 7.19 | 0.0 | 0.0 | 13 | 3 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, Go 1.26.5, `drvgo` `6de29ff`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvgo` and five for `buildGoModule`, with no competing host workloads.

### Reading the tradeoffs

- **Incremental edits and dependency updates**: Because `drvgo` plans package-granular derivations directly over the recursive Nix daemon socket, editing application code recompiles only the changed package (`main`) without rebuilding `github.com/google/uuid` or standard-library packages. Upgrading `uuid` from v1.5.0 to v1.6.0 reads `go.sum` directly, rebuilds only `uuid` and the application, and reuses every unchanged package from cache.
- **Cold builds and unchanged remote restores**: On this small single-package fixture, `buildGoModule` is faster on `cold` and `remote-warm`. `drvgo` compiles 136 package-granular derivations on a cold build (including individual Go standard-library packages so later edits and dependency updates can reuse them), and Nix 2.35 currently downloads build-time inputs of floating content-addressed derivations before looking up cached realisations on `remote-warm`.

[Detailed Go report](https://github.com/drvlang/drvgo/blob/6de29ff449b58072bb2b27909a44c3debad755d4/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvgo/blob/6de29ff449b58072bb2b27909a44c3debad755d4/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench)
