# Monorepos and CI {#monorepos}

A CI job often starts from an empty checkout and an empty compiler cache. If the whole repository is one build input, an edit to one command gives the entire build a new identity. Even a binary cache full of yesterday’s work can miss.

drvlang’s builders use dynamic derivations to plan work from native manifests, lockfiles, or compiler discovery. Nix can then track the inputs and outputs of smaller build steps. The available boundaries depend on the builder. For example, drvgo can compile individual Go packages, while drvjs can fetch individual pnpm packages and select workspace members.

## Share results between runners

Build outputs are content-addressed by default. Nix may run a changed library recipe once to discover its output. When its installed files and store references are identical, the library keeps its store path and downstream jobs can reuse their results. A program that also reads the edited source directly has a separate reason to rebuild, so keep each target's file set precise.

1. Point developer machines and CI runners at the same trusted Nix binary cache.
2. Request the package and its check in the same Nix invocation. Nix can schedule independent work in parallel and share dependency builds. Add each affected program when a change touches shared code.
3. Publish both named targets and their build traces. The traces tell another runner which output a recipe produced. The publishing and consuming versions of Nix must use a compatible build-trace format.

This Bash example builds and tests `api` on the current runner. It uses Nix 2.35 and a pinned copy of the shared publisher. Set `cache` to your writable binary cache.

```bash
set -euo pipefail
system=$(nix eval --impure --raw --expr builtins.currentSystem)
targets=(.#api ".#checks.$system.api")
nix build --no-link "${targets[@]}"
kit=$(nix flake prefetch --json github:drvlang/drvkit/58a935137f5fe6c222746a55096cd2751dee3398 | jq -er .storePath)
bash "$kit/publish-cache.sh" --upstream https://cache.nixos.org "$cache" "${targets[@]}"
```

The publisher includes build-only inputs such as crate downloads and compiler hooks that a clean runner can need to resolve a recipe. Both runners should have access to the chosen upstream cache. Omit `--upstream` to publish all the identified build inputs and their closures to your own cache. These can include project source, so use a private cache for private code. [Publisher source](https://github.com/drvlang/drvkit/blob/58a935137f5fe6c222746a55096cd2751dee3398/publish-cache.sh) · [Nix 2.35 build-trace format](https://nix.dev/manual/nix/2.35/release-notes/rl-2.35.html)

## Name the programs once

For a Go workspace with commands under `cmd/` and shared code under `pkg/`, a consumer flake can expose each command by name.

```nix
{
  inputs.drvgo.url = "github:drvlang/drvgo";
  outputs = { drvgo, ... }: drvgo.lib.mkMonorepoFlake {
    commands = {
      api = "cmd/api";
      worker = "cmd/worker";
    };
    srcForTarget = { target, ... }: drvgo.lib.projectSource {
      root = ./.;
      files = [ ./go.mod ./go.sum (./. + "/${target}") ./pkg/parser ];
    };
  };
}
```

Here both programs import `pkg/parser`, and the module has a `go.sum`. Each target receives its own command directory plus those shared inputs. Editing `cmd/worker` leaves the server’s package and test derivations unchanged. If a command embeds templates or reads fixtures, include those paths in its file set too.

Run `nix build .#api` to select the server. The [drvgo guide](https://github.com/drvlang/drvgo) lists the Nix features and toolchain settings for this build. See the [Go CI benchmarks](#benchmarks-go) for measured cold, cached, source-edit, and dependency-update timings against Nixpkgs’ `buildGoModule`.
