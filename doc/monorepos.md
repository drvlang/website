# Monorepos and CI {#monorepos}

A CI job often starts from an empty checkout and an empty compiler cache. If the whole repository is one build input, an edit to one command gives the entire build a new identity. Even a binary cache full of yesterday’s work can miss.

drvlang’s builders use dynamic derivations to plan work from native manifests, lockfiles, or compiler discovery. Nix can then track the inputs and outputs of smaller build steps. The available boundaries depend on the builder. For example, drvgo can compile individual Go packages, while drvjs can fetch individual pnpm packages and select workspace members.

## Share results between runners

Build outputs are content-addressed by default. Nix may run a changed library recipe once to discover its output. When its installed files and store references are identical, the library keeps its store path and downstream jobs can reuse their results. A program that also reads the edited source directly has a separate reason to rebuild, so keep each target's file set precise.

1. Point developer machines and CI runners at the same trusted Nix binary cache.
2. Build a named target. Nix uses local store paths first, substitutes matching paths from the cache, and schedules the missing work.
3. Publish the named target and its build traces. The traces tell another runner which output a recipe produced. The publishing and consuming versions of Nix must use a compatible build-trace format.

For Nix 2.35 and a new cache, the following command copies the intermediate CA outputs and their references along with the named target. This matters when a compiler tool or an intermediate library falls outside the executable’s runtime closure.

```bash
nix store build-trace info --recursive --json .#api |
  jq -r '.[] | select(.value) | "/nix/store/" + .value.outPath' |
  nix copy --to "$cache" --stdin .#api
```

A runner with builds disabled also needs substitutes for ordinary build inputs, including project-specific compiler dependencies. Keep the usual Nixpkgs cache enabled and publish any such inputs built only in your CI. The [Nix 2.35 release notes](https://nix.dev/manual/nix/2.35/release-notes/rl-2.35.html) describe the build-trace format change.

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

Run `nix build .#api` to select the server. The [drvgo guide](https://github.com/drvlang/drvgo) lists the Nix features and toolchain settings for this build.
