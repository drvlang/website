# CI Benchmarks {#benchmarks}

CIBench measures how long a CI worker takes to evaluate, build, and verify a real package and its behavior check under controlled CPU, memory, and binary-cache limits. Each workload runs a drvlang builder alongside the conventional Nixpkgs builder for the same language using the same pinned Nixpkgs and toolchain.

## What each test case measures

Every case runs in an independent chroot Nix store with strict sandboxing and import-from-derivation disabled. A **baseline** is the first successful cold build of that implementation, including its intermediate outputs, derivations, and content-addressed build traces. Edited runs can reuse baseline outputs, and their results are never published back to the cache.

| Test case | Project version | Local store at start | Project cache at start | What it models in CI |
| --- | --- | --- | --- | --- |
| `cold` | original | empty | empty | First build of a repository with no prior project cache (stock NixOS packages may still come from the upstream cache). |
| `remote-warm` | original | empty | baseline | A fresh ephemeral CI runner restoring an unchanged commit from the shared remote binary cache. |
| `local-warm` | original | baseline | empty | A persistent runner or developer machine re-evaluating and checking an unchanged commit whose outputs are already in the local Nix store. |
| `edit-remote` | source edit | empty | baseline | A fresh ephemeral CI runner building a pull request that edits application code while reusing cached dependencies from the remote binary cache. |
| `edit-local` | source edit | baseline | empty | A warm local runner or developer machine rebuilding after an application source edit. |
| `dependency-remote` | dependency update | empty | baseline | A fresh ephemeral CI runner building a lockfile bump while reusing unaffected cached work from the remote cache. |
| `dependency-local` | dependency update | baseline | empty | A warm local runner or developer machine rebuilding after a dependency update. |

## Go (`drvgo` vs. `buildGoModule`)

The Go workload builds a small command that depends on `github.com/google/uuid` and runs a check that executes the installed binary and verifies its output.

- **Original project**: builds the client against `github.com/google/uuid` v1.5.0 and checks its printed UUID version.
- **Source edit**: modifies `main.go` and the expected output without changing `go.mod` or `go.sum`.
- **Dependency update**: upgrades `github.com/google/uuid` from v1.5.0 to v1.6.0 in `go.mod` and `go.sum`. Because `buildGoModule` requires a separate Nix hash, it receives the matching updated `vendorHash` outside the timed job; `drvgo` reads the updated `go.sum` directly.

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

## JavaScript (`drvjs` vs. `fetchPnpmDeps`)

The JavaScript workload installs a small pnpm package (`number-demo`) that depends on `is-number` and runs a check that executes `node main.cjs` and verifies its output.

- **Original project**: installs `is-number` 6.0.0 from `pnpm-lock.yaml` and checks the output of `node main.cjs`.
- **Source edit**: modifies `main.cjs` and the expected output without changing `package.json` or `pnpm-lock.yaml`.
- **Dependency update**: upgrades `is-number` from 6.0.0 to 7.0.0 in `package.json` and `pnpm-lock.yaml`. Because `fetchPnpmDeps` requires a separate Nix hash, it receives the matching updated `hash` outside the timed job; `drvjs` reads the updated `pnpm-lock.yaml` directly.

### Results

On all four incremental CI cases (`edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`), `drvjs` is 2.0× to 4.4× faster than Nixpkgs `fetchPnpmDeps`, and cuts remote cache downloads nearly in half on `dependency-remote` (91.5 MiB vs. 175.5 MiB).

| Test case | `drvjs` (s) | `fetchPnpmDeps` (s) | `drvjs` cache download (MiB) | `fetchPnpmDeps` cache download (MiB) | `drvjs` recipes built | `fetchPnpmDeps` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 17.91 | 7.23 | 0.0 | 0.0 | 18 | 4 |
| `remote-warm` | 2.49 | 1.23 | 91.5 | 0.0 | 1 | 0 |
| `local-warm` | 0.93 | 0.97 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 2.56 | 5.15 | 91.5 | 93.7 | 6 | 3 |
| `edit-local` | 1.39 | 3.50 | 0.0 | 0.0 | 5 | 2 |
| `dependency-remote` | 2.55 | 8.59 | 91.5 | 175.5 | 7 | 4 |
| `dependency-local` | 1.46 | 6.36 | 0.0 | 0.0 | 6 | 3 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, Node.js 24.19.0, pnpm 10, `drvjs` `a7e664e`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvjs` and five for `fetchPnpmDeps`, with no competing host workloads.

### Reading the tradeoffs

- **Incremental edits and dependency updates**: `drvjs` plans package-granular derivations directly over the recursive Nix daemon socket and assembles `node_modules` natively without spawning `pnpm`. Editing application code reuses the fetched `is-number` tarball from cache, and upgrading `is-number` from 6.0.0 to 7.0.0 reads `pnpm-lock.yaml` directly, fetches only the updated tarball, and avoids rebuilding a monolithic fixed-output pnpm store.
- **Cold builds and unchanged remote restores**: On this single-dependency fixture, `fetchPnpmDeps` is faster on `cold` and `remote-warm`. A cold `drvjs` build compiles the minimal `drvjs` worker binary once (28 crates), and Nix 2.35 currently realizes the input-addressed check toolchain (`nodejs`) before looking up cached realisations of floating content-addressed derivations on `remote-warm`.

[Detailed JavaScript report](https://github.com/drvlang/drvjs/blob/a7e664eaca3ce33759ff4b589c1e774716b4d49d/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvjs/blob/a7e664eaca3ce33759ff4b589c1e774716b4d49d/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench)

## Rust (`drvrust` vs. `buildRustPackage`)

The Rust workload builds a small executable (`hex-demo`) that depends on `hex` and runs a check that executes the installed binary and verifies its printed hex output.

- **Original project**: builds `hex-demo` against `hex` 0.4.2 from `Cargo.lock` and checks its printed hex string.
- **Source edit**: modifies `src/main.rs` and the expected output without changing `Cargo.toml` or `Cargo.lock`.
- **Dependency update**: upgrades `hex` from 0.4.2 to 0.4.3 in `Cargo.toml` and `Cargo.lock` without any separate Nix hash.

### Results

On all four incremental CI cases (`edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`), `drvrust` is 1.3× to 2.2× faster than Nixpkgs `buildRustPackage`, matches `buildRustPackage` on `local-warm`, and cuts remote binary-cache downloads by 58% on remote edits and dependency updates (275 MiB vs. 661 MiB).

| Test case | `drvrust` (s) | `buildRustPackage` (s) | `drvrust` cache download (MiB) | `buildRustPackage` cache download (MiB) | `drvrust` recipes built | `buildRustPackage` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 6.84 | 5.89 | 0.0 | 0.0 | 9 | 5 |
| `remote-warm` | 4.49 | 1.25 | 275.4 | 15.9 | 0 | 0 |
| `local-warm` | 0.85 | 0.85 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 4.90 | 11.00 | 275.1 | 660.9 | 4 | 2 |
| `edit-local` | 1.29 | 2.08 | 0.0 | 0.0 | 4 | 2 |
| `dependency-remote` | 6.12 | 10.10 | 275.0 | 660.9 | 5 | 3 |
| `dependency-local` | 1.68 | 2.16 | 0.0 | 0.0 | 5 | 3 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, Rust 1.97.1, `drvrust` `a6dee65`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvrust` and five for `buildRustPackage`, with no competing host workloads.

### Reading the tradeoffs

- **Incremental edits and dependency updates**: `drvrust` plans per-crate derivations directly over the recursive Nix daemon socket using a slim `rustc` slice (dropping ~876 MiB of `rustc_private` metadata and compiler sources) and a minimal `ld.bfd` + CRT linker slice (dropping `gcc-15.3.0`). Source edits reuse prebuilt dependency `.rlib`s directly without invoking `cargo`, and dependency updates rebuild only the bumped crate and its dependents.
- **Cold builds and unchanged remote restores**: On this single-dependency fixture, `buildRustPackage` is slightly faster on `cold` (5.89 s vs. 6.84 s, where `drvrust` compiles its zero-crate planner once) and faster on `remote-warm` because Nix 2.35 currently fetches build-time inputs of floating content-addressed derivations before looking up cached realisations.

[Detailed Rust report](https://github.com/drvlang/drvrust/blob/a6dee65bc62812aef3a8e1f01b6bf1bc92de967b/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvrust/blob/a6dee65bc62812aef3a8e1f01b6bf1bc92de967b/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench)

## Python (`drvpy` vs. `buildPythonPackage`)

The Python workload packages a small console script (`format-demo`) that depends on `idna` and runs a check that executes `format-demo` and verifies its output.

- **Original project**: installs `idna` 3.10 from `uv.lock` and checks the output of `format-demo`.
- **Source edit**: modifies `format_demo.py` and the expected output without changing `pyproject.toml` or `uv.lock`.
- **Dependency update**: upgrades `idna` from 3.10 to 3.11 in `pyproject.toml` and `uv.lock` without any separate Nix hash.

### Results

`drvpy` is faster than Nixpkgs `buildPythonPackage` on six of seven cases — 2.0× faster on `cold`, 1.7× to 2.4× faster across all four incremental CI cases (`edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`), and faster on `local-warm` — while downloading 56% less from the remote binary cache on remote edits and dependency updates (93.8 MiB vs. 211.1 MiB).

| Test case | `drvpy` (s) | `buildPythonPackage` (s) | `drvpy` cache download (MiB) | `buildPythonPackage` cache download (MiB) | `drvpy` recipes built | `buildPythonPackage` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 1.92 | 3.85 | 0.0 | 0.0 | 6 | 3 |
| `remote-warm` | 2.07 | 1.95 | 93.8 | 86.9 | 0 | 0 |
| `local-warm` | 0.56 | 0.62 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 2.56 | 4.54 | 93.8 | 211.1 | 5 | 2 |
| `edit-local` | 1.21 | 2.10 | 0.0 | 0.0 | 5 | 2 |
| `dependency-remote` | 2.73 | 5.33 | 93.7 | 210.9 | 7 | 4 |
| `dependency-local` | 1.33 | 3.17 | 0.0 | 0.0 | 7 | 4 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, Python 3.14.7, `drvpy` `52bef74`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvpy` and five for `buildPythonPackage`, with no competing host workloads.

### Reading the tradeoffs

- **Cold builds, edits, and dependency updates**: Because `drvpy` runs a zero-dependency Python stdlib planner directly over the recursive Nix daemon socket and unpacks wheels natively into a PEP 405 virtual environment, it avoids `stdenv`, `gcc`, `uv`, and Nixpkgs Python build-system hooks. Source edits reuse every unpacked wheel from cache, and dependency updates read `uv.lock` directly and fetch only the bumped wheel.
- **Unchanged remote restores**: On `remote-warm`, `drvpy` (2.07 s, 93.8 MiB) is within 0.12 s of `buildPythonPackage` (1.95 s, 86.9 MiB), as both fetch the Python 3.14 runtime closure and the small package output.

[Detailed Python report](https://github.com/drvlang/drvpy/blob/52bef74a4d0a94d4249a7e4ef449402219748cab/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvpy/blob/52bef74a4d0a94d4249a7e4ef449402219748cab/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench)

## Ruby (`drvrb` vs. `bundlerEnv`)

The Ruby workload installs a small script (`bin/encode`) that depends on `base64` from `Gemfile.lock` and runs a check that executes `bin/encode` and verifies its output.

- **Original project**: installs `base64` 0.2.0 from `Gemfile.lock` and checks the output of `bin/encode`.
- **Source edit**: modifies `bin/encode` and the expected output without changing `Gemfile` or `Gemfile.lock`.
- **Dependency update**: upgrades `base64` from 0.2.0 to 0.3.0 in `Gemfile` and `Gemfile.lock`. Because `bundlerEnv` requires a separate generated `gemset.nix`, it receives the matching updated `gemset.nix` outside the timed job; `drvrb` reads the updated `Gemfile.lock` directly.

### Results

`drvrb` is faster than Nixpkgs `bundlerEnv` on `cold` (1.6× faster) and all four incremental CI cases (`edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`, 1.4× to 1.8× faster), while cutting remote binary-cache downloads by 76% on remote edits and dependency updates (43.6 MiB vs. 181.5 MiB).

| Test case | `drvrb` (s) | `bundlerEnv` (s) | `drvrb` cache download (MiB) | `bundlerEnv` cache download (MiB) | `drvrb` recipes built | `bundlerEnv` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 2.73 | 4.26 | 0.0 | 0.0 | 6 | 7 |
| `remote-warm` | 1.86 | 1.66 | 43.7 | 36.2 | 0 | 0 |
| `local-warm` | 0.93 | 0.91 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 2.60 | 4.66 | 43.6 | 181.5 | 3 | 6 |
| `edit-local` | 1.81 | 2.77 | 0.0 | 0.0 | 3 | 5 |
| `dependency-remote` | 3.00 | 5.36 | 43.6 | 181.5 | 6 | 7 |
| `dependency-local` | 2.28 | 3.23 | 0.0 | 0.0 | 6 | 6 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, Ruby 4.0.10, `drvrb` `133ef14`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvrb` and five for `bundlerEnv`, with no competing host workloads.

### Reading the tradeoffs

- **Cold builds, edits, and dependency updates**: `drvrb` runs a two-stage Ruby 4.0 planner directly over the recursive Nix daemon socket. After fetching locked `.gem` archives via `builtin:fetchurl`, it inspects each gem's gemspec and only realizes `stdenv`, `gcc`, and `pkg-config` for gems with native C extensions — pure-Ruby and precompiled platform gems install directly with RubyGems using only `ruby_4_0`, avoiding 138 MiB of C toolchain downloads on remote edits and dependency updates.
- **Unchanged restores**: `drvrb` is within 0.20 s of `bundlerEnv` on `remote-warm` (1.86 s vs. 1.66 s) and within 0.02 s on `local-warm` (0.93 s vs. 0.91 s), as both restore the Ruby 4.0 runtime closure and the small package output.

[Detailed Ruby report](https://github.com/drvlang/drvrb/blob/133ef142e87d71de7d4d54b651268e43523ad7a7/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvrb/blob/133ef142e87d71de7d4d54b651268e43523ad7a7/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench)
