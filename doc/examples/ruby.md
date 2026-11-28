# Ruby with GraphQL {#ruby}

Ruby's upstream benchmark suite locks the GraphQL parser, Racc, and their dependencies with Bundler. drvrb builds each selected gem in its own Nix derivation. It compiles Racc’s C extension and assembles the gems into a standard RubyGems folder.

```sh
git clone https://github.com/ruby/ruby-bench
git -C ruby-bench checkout c54da6e0161d2eab99e0aa60f75f5108f6cffa2e
nix run github:drvlang/drvrb -- build -C ruby-bench/benchmarks/graphql -o graphql-gems
./graphql-gems/bin/bundle check
./graphql-gems/bin/ruby -rgraphql -e 'puts GraphQL.parse("{ viewer { login } }").definitions.size'
```

The last command prints `1`. Inspect `graphql-gems/nix-support/gem-paths.json` to see each gem’s store path. Updating one gem preserves the paths of gems that do not depend on it. [Upstream Gemfile.lock](https://github.com/ruby/ruby-bench/blob/c54da6e0161d2eab99e0aa60f75f5108f6cffa2e/benchmarks/graphql/Gemfile.lock) · [drvrb flake and monorepo examples](https://github.com/drvlang/drvrb) · [Ruby CI benchmarks](#benchmarks-ruby)
