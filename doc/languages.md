# Language builders {#languages}

Start with the builder that matches your repository’s native dependency files. Each repository documents its supported formats, platform requirements, and benchmark workloads.

| Language and builder | Native project input |
| --- | --- |
| [Go (drvgo)](https://github.com/drvlang/drvgo) | Go modules, including `go.mod` and `go.sum` |
| [JavaScript and TypeScript (drvjs)](https://github.com/drvlang/drvjs) | pnpm workspaces and `pnpm-lock.yaml` |
| [Python (drvpy)](https://github.com/drvlang/drvpy) | uv projects and `uv.lock` |
| [Rust (drvrust)](https://github.com/drvlang/drvrust) | Cargo workspaces and `Cargo.lock` |
| [Java (drvjava)](https://github.com/drvlang/drvjava) | Maven artifacts locked by `rules_jvm_external` |
| [C# and .NET (drvnet)](https://github.com/drvlang/drvnet) | SDK projects with NuGet `packages.lock.json` |
| [C (drvc)](https://github.com/drvlang/drvc) | Meson C projects, including projects with hashed wrap archives |
| [C and C++ (drvcpp)](https://github.com/drvlang/drvcpp) | Meson projects with hashed wrap archives |

## What the builders share

The project is working toward the same build, test, and run experience in every language. Native lockfiles supply the integrity information. Updating a dependency should take one lockfile change, with no Nix dependency hash to maintain.

The builders use pinned open-source projects to exercise real code. Examples include Vue for JavaScript, Flask for Python, hexyl for Rust, and OpenH264 for C and C++. This site is rendered by [mmdoc](https://github.com/ryantm/mmdoc), a C project that uses drvc to build its executable and run its tests. Follow the builder links for commands and measurements.
