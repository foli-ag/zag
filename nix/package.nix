{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.default = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "foliag-zag";
        inherit (lib.importJSON ../package.json) version;

        # Everything but the Nix plumbing, so editing a module does not rebuild the library
        src = lib.fileset.toSource {
          root = ../.;
          fileset = lib.fileset.difference ../. (
            lib.fileset.unions [
              ../nix
              ../flake.nix
              ../flake.lock
            ]
          );
        };

        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs) pname version src;
          fetcherVersion = 4;
          hash = "sha256-xDfO7VKoByMdZqzOPjvXV6rEtu+TeTYdasNNGQPCW7M=";
        };

        nativeBuildInputs = [
          pkgs.nodejs
          pkgs.pnpm
          pkgs.pnpmConfigHook
        ];

        buildPhase = ''
          runHook preBuild
          pnpm build
          runHook postBuild
        '';

        # The npm tarball, ready for `pnpm publish ./result/foliag-zag-<version>.tgz`
        installPhase = ''
          runHook preInstall
          pnpm pack --pack-destination $out
          runHook postInstall
        '';
      });
    };
}
