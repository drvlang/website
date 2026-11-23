# About drvlang {#about}

Ryan Mulligan ([ryantm](https://github.com/ryantm)) created drvlang with help from AI. He also created [nixpkgs-update](https://github.com/NixOS/nixpkgs-update), the package update tool behind the [r-ryantm bot](https://github.com/r-ryantm).

The project asks how much work a monorepo can share across developers and CI jobs when the language’s own dependency graph is visible to Nix. Its goals are incremental builds, native lockfiles as the source of dependency integrity, and one interface for repositories written in different languages.

The [drvlang organization](https://github.com/drvlang) hosts the builders. The [shared project rules](https://github.com/drvlang/drvlang/blob/main/AGENTS.md) describe the contract for contributors.

This site is built from Markdown with [mmdoc](https://github.com/ryantm/mmdoc). Its [source and publishing workflow](https://github.com/drvlang/website) are public.
