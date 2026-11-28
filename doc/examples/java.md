# Java with Bazel’s IndexJar {#java}

IndexJar lists the classes in a JAR. Its source lives inside Bazel’s `rules_jvm_external` repository alongside a lockfile covering 169 Maven artifacts. To build this tool, drvjava starts from four coordinates for Gson, Kotlin metadata, the Kotlin standard library, and ASM. Their dependency closure contains six JARs.

```sh
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix build "github:drvlang/drvjava#checks.${system}.benchmark" -o indexjar-result
cat indexjar-result
```

The check compiles three upstream Java sources with the selected classpath and runs IndexJar on its own compiled JAR. The JSON output includes `com.github.bazelbuild.rules_jvm_external.jar.IndexJar`. A dependency change affects the relevant JAR fetches, while the project’s Java sources compile together. [IndexJar source](https://github.com/bazel-contrib/rules_jvm_external/tree/1ba9a81c928ca28ff4b592e7b20d131ba9b9a431/private/tools/java/com/github/bazelbuild/rules_jvm_external/jar) · [Flake recipe with the selected roots and sources](https://github.com/drvlang/drvjava/blob/main/benchmarks/default.nix) · [Java CI benchmarks](#benchmarks)
