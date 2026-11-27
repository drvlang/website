# Rust with hexyl {#rust}

hexyl reads bytes from standard input and displays their offsets, hexadecimal values, and text. Its Cargo lockfile pins each registry crate by checksum. drvrust fetches those crates individually, then Cargo compiles the selected package and runs its tests offline.

```sh
git clone --depth 1 --branch v0.17.0 https://github.com/sharkdp/hexyl
printf 'drvlang' | nix run github:drvlang/drvrust -- run -C hexyl -- --color=never
```

Look for `64 72 76 6c 61 6e 67` in the output. Each byte corresponds to a letter of `drvlang`. In a Cargo workspace, select the member directory with `drvrust build path/to/member`. [hexyl source](https://github.com/sharkdp/hexyl/tree/8eb6d4771ce1ec7af65d06bd335457783b77d557) · [drvrust workspace and flake options](https://github.com/drvlang/drvrust) · [Rust CI benchmarks](#benchmarks)
