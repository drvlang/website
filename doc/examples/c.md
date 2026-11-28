# C with mmdoc {#c}

mmdoc is the C program that renders this website. Its Meson project declares the renderer and tests. Its `drvlang.json` selects the sources, build tools, and system libraries, including cmark-gfm.

```sh
git clone https://github.com/ryantm/mmdoc
git -C mmdoc checkout 684ba64be908128d2092dfd13675397d4272b349
nix run github:drvlang/drvc -- test -C mmdoc -- --verbose
nix run github:drvlang/drvc -- run -C mmdoc -- mmdoc mmdoc/doc ./manual
```

Open `manual/multi/index.html` for the manual with separate pages, or `manual/single/index.html` to read it on one page. drvc lets Nix cache the selected Meson build. Ninja compiles its C source files inside that build. [mmdoc’s project configuration](https://github.com/ryantm/mmdoc/blob/684ba64be908128d2092dfd13675397d4272b349/drvlang.json) · [drvc project and flake options](https://github.com/drvlang/drvc) · [C CI benchmarks](#benchmarks-c)
