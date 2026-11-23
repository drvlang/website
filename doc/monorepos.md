# Monorepos and CI {#monorepos}

A CI job often starts from an empty checkout and an empty compiler cache. If the whole repository is one build input, an edit to one command gives the entire build a new identity. Even a binary cache full of yesterday’s work can miss.

drvlang’s builders use dynamic derivations to plan work from native manifests, lockfiles, or compiler discovery. Nix can then track the inputs and outputs of smaller build steps. The available boundaries depend on the builder. For example, drvgo can compile individual Go packages, while drvjs can fetch individual pnpm packages and select workspace members.

## Share results between runners

1. Point developer machines and CI runners at the same trusted Nix binary cache.
2. Build a named target. Nix uses local store paths first, substitutes matching paths from the cache, and schedules the missing work.
3. Publish reusable build outputs from successful jobs to that cache. A later job can substitute them even when it runs on another machine.

The cache must actually contain the intermediate outputs you want to share. A final executable can have a smaller runtime closure than the set of inputs used to build it. Configure the cache uploader to retain the build outputs that matter to your workload.

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
