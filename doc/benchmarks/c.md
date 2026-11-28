# C (drvc vs. stdenv.mkDerivation) {#benchmarks-c}

The C workload builds a Meson executable (`parse-ini`) that depends on `inih` via `subprojects/inih.wrap` and runs a check that executes `parse-ini` and verifies its output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: builds `parse-ini` against `inih` `r62` from `subprojects/inih.wrap` and checks its output.
- **Source edit**: modifies `main.c` and the expected output without changing `meson.build` or `subprojects/inih.wrap`.
- **Dependency update**: upgrades `inih` from `r62` to `r63` in `subprojects/inih.wrap` without any separate Nix hash.

## Results

`drvc` matches Nixpkgs `stdenv.mkDerivation` within 0.02–0.35 s across `local-warm`, `edit-remote`, `edit-local`, `dependency-remote`, and `dependency-local`, matches remote cache transfer on `edit-remote` (208.3 MiB), and transfers less than `stdenv.mkDerivation` on `dependency-remote` (208.2 MiB vs. 215.8 MiB) while reading Meson wrap locks directly.

| Test case | `drvc` (s) | `stdenv.mkDerivation` (s) | `drvc` cache download (MiB) | `stdenv.mkDerivation` cache download (MiB) | `drvc` recipes built | `stdenv.mkDerivation` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 4.16 | 3.52 | 0.0 | 0.0 | 5 | 3 |
| `remote-warm` | 3.37 | 1.17 | 208.3 | 11.9 | 0 | 0 |
| `local-warm` | 0.86 | 0.84 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 5.12 | 4.90 | 208.3 | 208.3 | 4 | 2 |
| `edit-local` | 2.70 | 2.48 | 0.0 | 0.0 | 4 | 2 |
| `dependency-remote` | 5.30 | 4.95 | 208.2 | 215.8 | 5 | 3 |
| `dependency-local` | 2.89 | 2.75 | 0.0 | 0.0 | 5 | 3 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, GCC 15.2.0, Meson 1.10.2, Ninja 1.13.2, `drvc` `b34dd39`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvc` and five for `stdenv.mkDerivation`, with no competing host workloads.

## Reading the tradeoffs

- **Edits and dependency updates**: `drvc` shares `drvcpp`'s Python 3 stdlib Meson planner (`pkgs.python3`, already in `pkgs.meson`'s closure), fetching wrap archives directly with `builtin:fetchurl` and emitting Meson build derivations directly over the recursive Nix daemon socket. Multi-component repositories can also isolate subprojects with `separateSubprojects` for content-addressed library caching.
- **Unchanged remote restores**: On this single-binary fixture, `stdenv.mkDerivation` is faster on `remote-warm` (1.17 s / 11.9 MiB vs. 3.37 s / 208.3 MiB) because Nix 2.35 currently realizes the build-time toolchain inputs of floating content-addressed derivations before looking up cached realisations.

[Detailed C report](https://github.com/drvlang/drvc/blob/b34dd392070ad8b7f03c51d6caa6bc11e514119d/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvc/blob/b34dd392070ad8b7f03c51d6caa6bc11e514119d/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [C worked example](#c)
