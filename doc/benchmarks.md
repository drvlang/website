# CI Benchmarks {#benchmarks}

CIBench measures how long a CI worker takes to evaluate, build, and verify a real package and its behavior check under controlled CPU, memory, and binary-cache limits. Each workload runs a drvlang builder alongside the conventional Nixpkgs builder for the same language using the same pinned Nixpkgs and toolchain.

## Results by language

Select a language for the full seven-case table, cache download sizes, recipe counts, methodology, and raw trial CSV.

| Language | drvlang builder | Nixpkgs comparator | `edit-remote` (drvlang vs. Nixpkgs) | `dependency-remote` (drvlang vs. Nixpkgs) | Full results |
| --- | --- | --- | ---: | ---: | --- |
| Go | `drvgo` | `buildGoModule` | 5.21 s vs. 10.18 s | 5.39 s vs. 9.86 s | [Go benchmarks](#benchmarks-go) |
| JavaScript | `drvjs` | `fetchPnpmDeps` | 2.56 s vs. 5.15 s | 2.55 s vs. 8.59 s | [JavaScript benchmarks](#benchmarks-javascript) |
| Python | `drvpy` | `buildPythonPackage` | 2.56 s vs. 4.54 s | 2.73 s vs. 5.33 s | [Python benchmarks](#benchmarks-python) |
| Ruby | `drvrb` | `bundlerEnv` | 2.60 s vs. 4.66 s | 3.00 s vs. 5.36 s | [Ruby benchmarks](#benchmarks-ruby) |
| Rust | `drvrust` | `buildRustPackage` | 4.90 s vs. 11.00 s | 6.12 s vs. 10.10 s | [Rust benchmarks](#benchmarks-rust) |
| Java | `drvjava` | `buildMavenPackage` | 3.55 s vs. 11.07 s | 3.77 s vs. 22.55 s | [Java benchmarks](#benchmarks-java) |
| .NET | `drvnet` | `buildDotnetModule` | 8.54 s vs. 12.66 s | 10.27 s vs. 12.62 s | [.NET benchmarks](#benchmarks-dotnet) |
| C | `drvc` | `stdenv.mkDerivation` | 5.12 s vs. 4.90 s | 5.30 s vs. 4.95 s | [C benchmarks](#benchmarks-c) |
| C++ | `drvcpp` | `stdenv.mkDerivation` | 5.47 s vs. 5.22 s | 6.19 s vs. 5.28 s | [C++ benchmarks](#benchmarks-cpp) |

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

All runs use the [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages).
