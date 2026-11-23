{
  description = "drvlang.org, built with mmdoc";
  inputs.mmdoc.url = "github:ryantm/mmdoc";
  inputs.nixpkgs.follows = "mmdoc/nixpkgs";
  outputs = { mmdoc, nixpkgs, ... }:
    let eachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    in {
      packages = eachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.runCommand "drvlang-website" {
          nativeBuildInputs = [ mmdoc.packages.${system}.default ];
        } ''
          mmdoc drvlang ${./doc} generated
          cp -r generated/multi "$out"
          cp ${./assets/snowball.png} "$out/snowball.png"
          cp ${./assets/site.css} "$out/site.css"
          for page in $(find "$out" -name index.html); do
            substituteInPlace "$page" \
              --replace-fail "href='favicon.svg'" "href='snowball.png'" \
              --replace-fail '</head>' "<link rel='stylesheet' href='site.css'></head>"
          done
          test -s "$out/index.html"
          test -s "$out/languages/index.html"
        '';
      });
    };
}
