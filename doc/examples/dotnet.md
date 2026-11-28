# C# with Microsoft Dev Proxy {#dotnet}

Microsoft’s Dev Proxy reads configuration from Markdown front matter. Its C# implementation lives in `DevProxy.Abstractions.csproj`. drvnet follows the MSBuild project graph, fetches the NuGet packages in `packages.lock.json`, and gives the .NET SDK a local feed for a locked restore.

```sh
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix build "github:drvlang/drvnet#checks.${system}.benchmark" -o dev-proxy-result
cat dev-proxy-result
```

This builds the assembly with .NET 10 and 37 locked packages. A small C# client loads that assembly and checks that the parser returns both the front-matter title and the Markdown body. It prints `Parsed front matter and Markdown body`. [Dev Proxy project](https://github.com/microsoft/dev-proxy/tree/e1409ec952041c441cad237f8c0b3872ff507614/DevProxy.Abstractions) · [Nix build and C# client](https://github.com/drvlang/drvnet/tree/main/benchmarks) · [.NET CI benchmarks](#benchmarks)
