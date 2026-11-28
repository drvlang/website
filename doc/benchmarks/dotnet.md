# .NET (drvnet vs. buildDotnetModule) {#benchmarks-dotnet}

The .NET workload builds a small .NET 10 console application (`Demo`) that depends on `Newtonsoft.Json` from `packages.lock.json` and runs a check that executes `bin/Demo` and verifies its JSON output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: builds `Demo` against `Newtonsoft.Json` 13.0.1 from `packages.lock.json` and checks the output of `bin/Demo`.
- **Source edit**: modifies `Program.cs` and the expected output without changing `Demo.csproj` or `packages.lock.json`.
- **Dependency update**: upgrades `Newtonsoft.Json` from 13.0.1 to 13.0.3 in `packages.lock.json`. Because `buildDotnetModule` requires a separate generated `deps.json`, it receives the updated `deps.json` outside the timed job; `drvnet` reads the updated `packages.lock.json` directly.

## Results

`drvnet` beats Nixpkgs `buildDotnetModule` on `local-warm`, `edit-remote` (1.5× faster), `edit-local` (1.5× faster), and `dependency-remote` (1.2× faster), stays within 0.29 s on `dependency-local`, and cuts remote binary-cache downloads by 55% on remote edits and dependency updates (211–213 MiB vs. 475–477 MiB).

| Test case | `drvnet` (s) | `buildDotnetModule` (s) | `drvnet` cache download (MiB) | `buildDotnetModule` cache download (MiB) | `drvnet` recipes built | `buildDotnetModule` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 14.99 | 9.48 | 0.0 | 0.0 | 7 | 2 |
| `remote-warm` | 3.99 | 2.26 | 213.3 | 73.6 | 0 | 0 |
| `local-warm` | 1.03 | 1.08 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 8.54 | 12.66 | 213.0 | 477.3 | 2 | 2 |
| `edit-local` | 4.86 | 7.06 | 0.0 | 0.0 | 2 | 2 |
| `dependency-remote` | 10.27 | 12.62 | 211.0 | 475.2 | 5 | 2 |
| `dependency-local` | 7.38 | 7.09 | 0.0 | 0.0 | 5 | 2 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, .NET SDK 10.0.302, `drvnet` `725401a`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvnet` and five for `buildDotnetModule`, with no competing host workloads.

## Reading the tradeoffs

- **Edits and dependency updates**: `drvnet` runs a self-contained C# .NET 10 planner directly over the recursive Nix daemon socket, fetches and verifies each locked `.nupkg` individually from `packages.lock.json`, and uses an input-addressed slim .NET SDK slice (`sdkSlim`) that drops 376 MiB of unused project templates, bundled global tools, satellite DLLs, and NativeAOT/self-contained runtime packs — cutting remote binary-cache transfers in half compared to `buildDotnetModule`.
- **Cold builds and unchanged remote restores**: On this single-dependency fixture, `buildDotnetModule` is faster on `cold` (9.48 s vs. 14.99 s, where `drvnet` builds `sdkSlim` and its C# helper once) and on `remote-warm` (2.26 s / 73.6 MiB vs. 3.99 s / 213.3 MiB) because Nix 2.35 currently realizes the build-time SDK inputs of floating content-addressed derivations before looking up cached realisations.

[Detailed .NET report](https://github.com/drvlang/drvnet/blob/725401af01d2169655366d432df09d0202e28795/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvnet/blob/725401af01d2169655366d432df09d0202e28795/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [.NET worked example](#dotnet)
