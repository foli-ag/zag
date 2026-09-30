{
  perSystem =
    { self', ... }:
    let
      # Runs a package.json script against the package's source and offline pnpm store
      pnpmScript =
        script:
        self'.packages.default.overrideAttrs {
          name = "foliag-zag-${script}";
          buildPhase = ''
            runHook preBuild
            pnpm ${script}
            runHook postBuild
          '';
          installPhase = "touch $out";
        };
    in
    {
      checks = {
        package = self'.packages.default;
        typecheck = pnpmScript "typecheck";
        test = pnpmScript "test";
      };
    };
}
