# Ruby (drvrb vs. bundlerEnv) {#benchmarks-ruby}

The Ruby workload installs a small script (`bin/encode`) that depends on `base64` from `Gemfile.lock` and runs a check that executes `bin/encode` and verifies its output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: installs `base64` 0.2.0 from `Gemfile.lock` and checks the output of `bin/encode`.
- **Source edit**: modifies `bin/encode` and the expected output without changing `Gemfile` or `Gemfile.lock`.
- **Dependency update**: upgrades `base64` from 0.2.0 to 0.3.0 in `Gemfile` and `Gemfile.lock`. Because `bundlerEnv` requires a separate generated `gemset.nix`, it receives the matching updated `gemset.nix` outside the timed job; `drvrb` reads the updated `Gemfile.lock` directly.

## Results

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

## Reading the tradeoffs

- **Cold builds, edits, and dependency updates**: `drvrb` runs a two-stage Ruby 4.0 planner directly over the recursive Nix daemon socket. After fetching locked `.gem` archives via `builtin:fetchurl`, it inspects each gem's gemspec and only realizes `stdenv`, `gcc`, and `pkg-config` for gems with native C extensions — pure-Ruby and precompiled platform gems install directly with RubyGems using only `ruby_4_0`, avoiding 138 MiB of C toolchain downloads on remote edits and dependency updates.
- **Unchanged restores**: `drvrb` is within 0.20 s of `bundlerEnv` on `remote-warm` (1.86 s vs. 1.66 s) and within 0.02 s on `local-warm` (0.93 s vs. 0.91 s), as both restore the Ruby 4.0 runtime closure and the small package output.

[Detailed Ruby report](https://github.com/drvlang/drvrb/blob/133ef142e87d71de7d4d54b651268e43523ad7a7/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvrb/blob/133ef142e87d71de7d4d54b651268e43523ad7a7/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [Ruby worked example](#ruby)
