# JavaScript (drvjs vs. fetchPnpmDeps) {#benchmarks-javascript}

The JavaScript workload installs a small pnpm package (`number-demo`) that depends on `is-number` and runs a check that executes `node main.cjs` and verifies its output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: installs `is-number` 6.0.0 from `pnpm-lock.yaml` and checks the output of `node main.cjs`.
- **Source edit**: modifies `main.cjs` and the expected output without changing `package.json` or `pnpm-lock.yaml`.
- **Dependency update**: upgrades `is-number` from 6.0.0 to 7.0.0 in `package.json` and `pnpm-lock.yaml`. Because `fetchPnpmDeps` requires a separate Nix hash, it receives the matching updated `hash` outside the timed job; `drvjs` reads the updated `pnpm-lock.yaml` directly.

## Results

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

## Reading the tradeoffs

- **Incremental edits and dependency updates**: `drvjs` plans package-granular derivations directly over the recursive Nix daemon socket and assembles `node_modules` natively without spawning `pnpm`. Editing application code reuses the fetched `is-number` tarball from cache, and upgrading `is-number` from 6.0.0 to 7.0.0 reads `pnpm-lock.yaml` directly, fetches only the updated tarball, and avoids rebuilding a monolithic fixed-output pnpm store.
- **Cold builds and unchanged remote restores**: On this single-dependency fixture, `fetchPnpmDeps` is faster on `cold` and `remote-warm`. A cold `drvjs` build compiles the minimal `drvjs` worker binary once (28 crates), and Nix 2.35 currently realizes the input-addressed check toolchain (`nodejs`) before looking up cached realisations of floating content-addressed derivations on `remote-warm`.

[Detailed JavaScript report](https://github.com/drvlang/drvjs/blob/a7e664eaca3ce33759ff4b589c1e774716b4d49d/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvjs/blob/a7e664eaca3ce33759ff4b589c1e774716b4d49d/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [JavaScript worked example](#javascript)
