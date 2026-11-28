# Java (drvjava vs. buildMavenPackage) {#benchmarks-java}

The Java workload compiles a small application (`json-demo`) that depends on `com.google.code.gson:gson` from `maven_install.json` and runs a check that executes `drvjava-run` and verifies its JSON output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: builds `json-demo` against `gson` 2.10.1 from `maven_install.json` and checks its output.
- **Source edit**: modifies `Main.java` and the expected output without changing `maven_install.json`.
- **Dependency update**: upgrades `gson` from 2.10.1 to 2.11.0 in `maven_install.json`. Because `buildMavenPackage` requires a separate Maven fixed-output hash, it receives the updated `maven-hash` outside the timed job; `drvjava` reads the updated `maven_install.json` directly.

## Results

`drvjava` beats Nixpkgs `buildMavenPackage` on all seven CI cases — 2.4× faster on `cold`, 2.6× faster on `remote-warm`, 1.9× to 6.0× faster across all four incremental cases (`edit-remote`, `edit-local`, `dependency-remote`, `dependency-local`), and faster on `local-warm` — while cutting remote binary-cache downloads by 4.5× to 12.0× (97 MiB vs. 441–1168 MiB).

| Test case | `drvjava` (s) | `buildMavenPackage` (s) | `drvjava` cache download (MiB) | `buildMavenPackage` cache download (MiB) | `drvjava` recipes built | `buildMavenPackage` recipes built |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `cold` | 6.64 | 15.84 | 0.0 | 0.0 | 8 | 11 |
| `remote-warm` | 2.72 | 7.19 | 97.3 | 440.7 | 0 | 0 |
| `local-warm` | 1.15 | 1.19 | 0.0 | 0.0 | 0 | 0 |
| `edit-remote` | 3.55 | 11.07 | 97.3 | 588.8 | 3 | 2 |
| `edit-local` | 2.09 | 3.89 | 0.0 | 0.0 | 3 | 2 |
| `dependency-remote` | 3.77 | 22.55 | 97.1 | 1167.9 | 5 | 11 |
| `dependency-local` | 2.36 | 10.86 | 0.0 | 0.0 | 5 | 3 |

Times are medians on x86_64 Linux (Intel Core i7-1280P, Nix 2.35.3, OpenJDK 21.0.12+8, `drvjava` `9c6ba49`, 4 CPUs, 8 GiB RAM, 0 swap, simulated project cache with 5 ms latency and 100 MiB/s bandwidth, plus a local mirror of signed NixOS packages): three trials for `drvjava` and five for `buildMavenPackage`, with no competing host workloads.

## Reading the tradeoffs

- **All cold, warm, edit, and dependency cases**: `drvjava` runs a pure-JDK Java 21 planner directly over the recursive Nix daemon socket, fetches each locked JAR with `builtin:fetchurl`, compiles sources in-process via `ToolProvider.getSystemJavaCompiler()`, and uses an input-addressed slim JDK slice (`jdkSlim`) that drops 359 MiB of unused `jmods/` and `lib/src.zip` with zero references to the full JDK store path.
- **No Maven runtime or monolithic `.m2` hash**: Unlike `buildMavenPackage`, which pulls Maven and a full `.m2` fixed-output repository on cold builds and dependency updates (1168 MiB on `dependency-remote`), `drvjava` reads `maven_install.json` directly and fetches only the bumped JAR.

[Detailed Java report](https://github.com/drvlang/drvjava/blob/9c6ba49b025d31e7c9c3af3143f559f3a0c475f8/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvjava/blob/9c6ba49b025d31e7c9c3af3143f559f3a0c475f8/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [Java worked example](#java)
