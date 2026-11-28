# Python (drvpy vs. buildPythonPackage) {#benchmarks-python}

The Python workload packages a small console script (`format-demo`) that depends on `idna` and runs a check that executes `format-demo` and verifies its output. See [CI Benchmarks](#benchmarks) for what each test case measures.

- **Original project**: installs `idna` 3.10 from `uv.lock` and checks the output of `format-demo`.
- **Source edit**: modifies `format_demo.py` and the expected output without changing `pyproject.toml` or `uv.lock`.
- **Dependency update**: upgrades `idna` from 3.10 to 3.11 in `pyproject.toml` and `uv.lock` without any separate Nix hash.

## Results

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

## Reading the tradeoffs

- **Cold builds, edits, and dependency updates**: Because `drvpy` runs a zero-dependency Python stdlib planner directly over the recursive Nix daemon socket and unpacks wheels natively into a PEP 405 virtual environment, it avoids `stdenv`, `gcc`, `uv`, and Nixpkgs Python build-system hooks. Source edits reuse every unpacked wheel from cache, and dependency updates read `uv.lock` directly and fetch only the bumped wheel.
- **Unchanged remote restores**: On `remote-warm`, `drvpy` (2.07 s, 93.8 MiB) is within 0.12 s of `buildPythonPackage` (1.95 s, 86.9 MiB), as both fetch the Python 3.14 runtime closure and the small package output.

[Detailed Python report](https://github.com/drvlang/drvpy/blob/52bef74a4d0a94d4249a7e4ef449402219748cab/benchmarks/cibench-ci-optimizations-2026-11-27.md) · [Raw trial CSV](https://github.com/drvlang/drvpy/blob/52bef74a4d0a94d4249a7e4ef449402219748cab/benchmarks/cibench-ci-optimizations-2026-11-27.csv) · [CIBench harness](https://github.com/drvlang/drvkit/tree/main/cibench) · [Python worked example](#python)
