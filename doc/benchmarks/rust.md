# Rust (drvrust vs. buildRustPackage) {#benchmarks-rust}

The Rust workload builds a small executable (`hex-demo`) that depends on `hex` and runs a check that executes the installed binary and verifies its printed hex output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: builds `hex-demo` against `hex` 0.4.2 from `Cargo.lock` and checks its printed hex string.
- **Source edit**: modifies `src/main.rs` and the expected output without changing `Cargo.toml` or `Cargo.lock`.
- **Dependency update**: upgrades `hex` from 0.4.2 to 0.4.3 in `Cargo.toml` and `Cargo.lock` without any separate Nix hash.

## Results

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

## Reading the tradeoffs

- **Incremental edits and dependency updates**: `drvrust` plans per-crate derivations directly over the recursive Nix daemon socket using a slim `rustc` slice (dropping ~876 MiB of `rustc_private` metadata and compiler sources) and a minimal `ld.bfd` + CRT linker slice (dropping `gcc-15.3.0`). Source edits reuse prebuilt dependency `.rlib`s directly without invoking `cargo`, and dependency updates rebuild only the bumped crate and its dependents.
- **Cold builds and unchanged remote restores**: On this single-dependency fixture, `buildRustPackage` is slightly faster on `cold` (5.89 s vs. 6.84 s, where `drvrust` compiles its zero-crate planner once) and faster on `remote-warm` because Nix 2.35 currently fetches build-time inputs of floating content-addressed derivations before looking up cached realisations.

[Detailed Rust report](https://github.com/drvlang/drvrust/blob/a6dee65bc62812aef3a8e1f01b6bf1bc92de967b/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvrust/blob/a6dee65bc62812aef3a8e1f01b6bf1bc92de967b/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [Rust worked example](#rust)
