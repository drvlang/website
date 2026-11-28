# C++ (drvcpp vs. stdenv.mkDerivation) {#benchmarks-cpp}

The C++ workload builds a Meson executable (`parse-ini`) that depends on `inih` via `subprojects/inih.wrap` and runs a check that executes `parse-ini` and verifies its output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: builds `parse-ini` against `inih` `r62` from `subprojects/inih.wrap` and checks its output.
- **Source edit**: modifies `main.cpp` and the expected output without changing `meson.build` or `subprojects/inih.wrap`.
- **Dependency update**: upgrades `inih` from `r62` to `r63` in `subprojects/inih.wrap` without any separate Nix hash.

## Results

`drvcpp` matches Nixpkgs `stdenv.mkDerivation` within 0.03–0.25 s on `local-warm`, `edit-remote`, `edit-local`, and `dependency-local`, matches remote cache transfer on `edit-remote` (213.7 MiB), and transfers less than `stdenv.mkDerivation` on `dependency-remote` (213.6 MiB vs. 221.2 MiB) while reading Meson wrap locks directly.

| Test case | `drvcpp` (s) | `stdenv.mkDerivation` (s) | `drvcpp` cache download (MiB) | `stdenv.mkDerivation` cache download (MiB) | `drvcpp` recipes built | `stdenv.mkDerivation` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 4.19 | 3.73 | 0.0 | 0.0 | 5 | 3 |
| `remote-warm` | 3.26 | 1.01 | 213.7 | 11.9 | 0 | 0 |
| `local-warm` | 0.70 | 0.67 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 5.47 | 5.22 | 213.7 | 213.7 | 4 | 2 |
| `edit-local` | 2.98 | 2.76 | 0.0 | 0.0 | 4 | 2 |
| `dependency-remote` | 6.19 | 5.28 | 213.6 | 221.2 | 5 | 3 |
| `dependency-local` | 3.18 | 3.01 | 0.0 | 0.0 | 5 | 3 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, GCC 15.3.0, Meson 1.10.2, Ninja 1.13.2, `drvcpp` `7b13e6e`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvcpp` and five for `stdenv.mkDerivation`, with no competing host workloads.

## Reading the tradeoffs

- **Edits and dependency updates**: `drvcpp` parses `subprojects/*.wrap` directly in a Python 3 stdlib planner (reusing `pkgs.python3` already in `pkgs.meson`'s closure), fetches wrap archives via `builtin:fetchurl` (avoiding `curl` and its dev closure), and emits the Meson build derivation directly over the recursive Nix daemon socket. When a multi-component project declares `separateSubprojects`, unchanged libraries are cached as independent content-addressed derivations.
- **Unchanged remote restores**: On this single-binary fixture, `stdenv.mkDerivation` is faster on `remote-warm` (1.01 s / 11.9 MiB vs. 3.26 s / 213.7 MiB) because Nix 2.35 currently realizes the build-time toolchain inputs of floating content-addressed derivations before looking up cached realisations.

[Detailed C++ report](https://github.com/drvlang/drvcpp/blob/7b13e6eba391ae53853ab3d909713025e8e35699/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvcpp/blob/7b13e6eba391ae53853ab3d909713025e8e35699/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [C++ worked example](#cpp)
