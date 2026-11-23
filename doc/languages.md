# Language builders {#languages}

Start with the builder that matches your repository’s native dependency files. Each repository documents its supported formats, platform requirements, and benchmark workloads.

| Language | Native project input | Builder |
| --- | --- | --- |
| Go | Go modules, including `go.mod` and `go.sum` | [drvgo](https://github.com/drvlang/drvgo) |
| JavaScript and TypeScript | pnpm workspaces and `pnpm-lock.yaml` | [drvjs](https://github.com/drvlang/drvjs) |
| Python | uv projects and `uv.lock` | [drvpy](https://github.com/drvlang/drvpy) |
| Rust | Cargo workspaces and `Cargo.lock` | [drvrust](https://github.com/drvlang/drvrust) |
| Java | Maven artifacts locked by `rules_jvm_external` | [drvjava](https://github.com/drvlang/drvjava) |
| C# and .NET | SDK projects with NuGet `packages.lock.json` | [drvnet](https://github.com/drvlang/drvnet) |
| C and C++ | Meson projects with hashed wrap archives | [drvcpp](https://github.com/drvlang/drvcpp) |

## What the builders share

The project is working toward the same build, test, and run experience in every language. Native lockfiles supply the integrity information. Updating a dependency should take one lockfile change, with no Nix dependency hash to maintain.

The builders use pinned open-source projects to exercise real code. Examples include Vue for JavaScript, Flask for Python, hexyl for Rust, and OpenH264 for C and C++. Follow the builder links for commands and measurements.
