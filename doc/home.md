# Build and test across languages with Nix {#overview}

![The drvlang snowball rolling downhill](snowball.png)

drvlang brings Go, JavaScript, TypeScript, Python, Ruby, Rust, Java, C#, C, and C++ projects into the Nix binary cache. Start with the dependency files your project already uses. Each language has a builder with the same three commands — `build`, `test`, and `run`.

## Choose a language

| Language | Try it on a real project |
| --- | --- |
| Go | [Build Replit’s package manager and its database generator](#go) |
| JavaScript | [Parse a stylesheet with PostCSS](#javascript) |
| TypeScript | [Run Vue’s computed-property tests](#typescript) |
| Python | [Test Flask with its uv environment](#python) |
| Ruby | [Build a gem folder and parse a GraphQL query](#ruby) |
| Rust | [Inspect bytes with the hexyl command-line tool](#rust) |
| Java | [Find Java classes with Bazel’s JAR indexer](#java) |
| C# / .NET | [Parse Markdown with Microsoft’s Dev Proxy](#dotnet) |
| C | [Render a manual with mmdoc](#c) |
| C++ | [Initialize an OpenH264 video encoder](#cpp) |

## Share work across CI runners

When a dependency changes, commit the updated native lockfile. The builder reads it during the build and asks Nix to fetch the locked dependencies. A new runner can reuse outputs already published to your binary cache. What it reuses depends on the language, from individual Go package compilations to downloaded crates, JARs, or pnpm packages.

In a monorepo, give each program a name and specify the sources, manifests, and shared code it reads. An edit to an unrelated program can then leave the selected target’s build and test outputs reusable. [Configure Nix for your builder](#languages) · [Set up a monorepo and CI cache](#monorepos)
