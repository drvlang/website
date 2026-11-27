# Go with Replit UPM {#go}

Replit’s Universal Package Manager needs two Go executables. One is the `upm` command. The other generates a SQLite database that lets UPM look up Python packages. drvgo builds both from the same `go.mod` and `go.sum`. Each imported Go package has its own compilation derivation, so the two executables can share compiled dependencies.

```sh
git clone --depth 1 https://github.com/drvlang/drvgo
nix-build drvgo/examples/upm/dynamic.nix -A package
./result/bin/upm list-languages
```

The example fetches a pinned UPM revision, runs the database generator, and installs the command with the database path configured. The last line prints the languages UPM recognizes. To build an individual command in your own module, use `drvgo build ./cmd/app`. [UPM source](https://github.com/replit/upm/tree/35a76c282507fb942445c0ee98427b3d1ef772bc) · [Build recipe](https://github.com/drvlang/drvgo/tree/main/examples/upm) · [Go monorepo example](#monorepos) · [Go CI benchmarks](#benchmarks)
