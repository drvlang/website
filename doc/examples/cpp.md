# C++ with OpenH264 {#cpp}

Cisco’s OpenH264 is a C++ video codec. Its Meson build uses GoogleTest from a wrap archive with a pinned checksum and patch. drvcpp fetches those inputs, enables the project’s tests, and installs the compiled codec. The example also supplies NASM for x86 builds.

```sh
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix build "github:drvlang/drvcpp#checks.${system}.benchmark" -o openh264-result
cat openh264-result
```

A separate C++ client links against the installed library, initializes an encoder with `WelsCreateSVCEncoder`, reads its default parameters, and prints the codec version. Nix can reuse the locked archive downloads and the built codec when rebuilding the client. [OpenH264 source](https://github.com/cisco/openh264/tree/78783f195ce116ecbaea83f7fac0ea8a355518b5) · [Meson build and C++ client](https://github.com/drvlang/drvcpp/tree/main/benchmarks)
