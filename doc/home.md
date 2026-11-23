# Incremental builds with Nix {#overview}

![The drvlang snowball rolling downhill](snowball.png)

drvlang turns a language’s native build graph into work that Nix can cache. The goal is to change one program in a monorepo and let the next CI runner pick up everything its predecessors already built.

## One edit in a monorepo

Imagine a Go repository with an API server, a background worker, and a shared parser. You fix a handler that only the server imports. The worker’s inputs are unchanged. A CI runner with an empty local store can fetch the worker from your Nix binary cache and spend its build time on the server.

Changing the shared parser is a different edit. Both programs depend on it, so both paths through the graph may need work. Which outputs can be reused follows from their inputs, even when the two CI runs happen on different machines.

[See how a CI build uses the cache](#monorepos) · [Find your language](#languages)
