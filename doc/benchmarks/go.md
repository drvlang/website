# Go (drvgo vs. buildGoModule) {#benchmarks-go}

The Go workload builds a small command that depends on `github.com/google/uuid` and runs a check that executes the installed binary and verifies its output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: builds the client against `github.com/google/uuid` v1.5.0 and checks its printed UUID version.
- **Source edit**: modifies `main.go` and the expected output without changing `go.mod` or `go.sum`.
- **Dependency update**: upgrades `github.com/google/uuid` from v1.5.0 to v1.6.0 in `go.mod` and `go.sum`. Because `buildGoModule` requires a separate Nix hash, it receives the matching updated `vendorHash` outside the timed job; `drvgo` reads the updated `go.sum` directly.

## Results

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

## Reading the tradeoffs

- **Incremental edits and dependency updates**: Because `drvgo` plans package-granular derivations directly over the recursive Nix daemon socket, editing application code recompiles only the changed package (`main`) without rebuilding `github.com/google/uuid` or standard-library packages. Upgrading `uuid` from v1.5.0 to v1.6.0 reads `go.sum` directly, rebuilds only `uuid` and the application, and reuses every unchanged package from cache.
- **Cold builds and unchanged remote restores**: On this small single-package fixture, `buildGoModule` is faster on `cold` and `remote-warm`. `drvgo` compiles 136 package-granular derivations on a cold build (including individual Go standard-library packages so later edits and dependency updates can reuse them), and Nix 2.35 currently downloads build-time inputs of floating content-addressed derivations before looking up cached realisations on `remote-warm`.

[Detailed Go report](https://github.com/drvlang/drvgo/blob/6de29ff449b58072bb2b27909a44c3debad755d4/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvgo/blob/6de29ff449b58072bb2b27909a44c3debad755d4/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [Go worked example](#go)
