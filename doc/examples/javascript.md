# JavaScript with PostCSS {#javascript}

PostCSS parses CSS into a tree that JavaScript plugins can inspect and edit. Build it from its pnpm lockfile and ask the parser for the selector and value in a small stylesheet.

```sh
git clone --depth 1 --branch 8.5.6 https://github.com/postcss/postcss
nix run github:drvlang/drvjs -- build -C postcss
cd postcss/result
nix shell --inputs-from github:drvlang/drvjs nixpkgs#nodejs --command node <<'JS'
const postcss = require('./lib/postcss')
const css = postcss.parse('h1 { color: navy }')
console.log(css.first.selector, css.first.first.value)
JS
```

The built project prints `h1 navy`. drvjs installs the application and its locked dependencies. Each downloaded tarball has its own Nix store path, so other JavaScript builds can reuse it. [PostCSS source](https://github.com/postcss/postcss/tree/91d6eb5c3d1ca8acb4e8e3926005acf2b066c211) · [drvjs workspace and flake options](https://github.com/drvlang/drvjs)
