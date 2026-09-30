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

        # node_modules as `bun install` lays it out. A fixed-output derivation, so it may reach the
        # registry. It installs the optional native packages of every platform, so one hash serves all systems.
        bunDeps = pkgs.stdenvNoCC.mkDerivation {
          name = "${finalAttrs.pname}-node-modules-${finalAttrs.version}";

          src = lib.fileset.toSource {
            root = ../.;
            fileset = lib.fileset.unions [
              ../package.json
              ../bun.lock
              ../bunfig.toml
            ];
          };

          nativeBuildInputs = [ pkgs.bun ];

          dontConfigure = true;
          # Fixing up would patch store paths into node_modules, which a fixed-output derivation cannot reference
          dontFixup = true;

          buildPhase = ''
            runHook preBuild
            export HOME=$TMPDIR
            bun install --frozen-lockfile --ignore-scripts --os='*' --cpu='*' --no-progress
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            # Whether bun links a dependency's binaries into a package's own .bin depends on the order the
            # tarballs arrive in, which changes the hash from one machine to the next. Only dependency lifecycle
            # scripts use those links, and --ignore-scripts skips them.
            find node_modules/.bun -mindepth 3 -maxdepth 3 -name .bin -prune -exec rm -rf {} +
            mkdir $out
            cp -a node_modules $out
            runHook postInstall
          '';

          outputHashMode = "recursive";
          outputHash = "sha256-PbZ5bRvjc+8lzFTrzzmQB8GxmlCxQndFBTtmevDtKgo=";
        };

        # Node runs vite, vitest and tsup, which are written for it. Bun installs and runs the scripts.
        nativeBuildInputs = [
          pkgs.bun
          pkgs.nodejs
        ];

        configurePhase = ''
          runHook preConfigure
          export HOME=$TMPDIR
          cp -a ${finalAttrs.bunDeps}/node_modules .
          chmod -R u+w node_modules
          # The sandbox has no /usr/bin/env for the `#!/usr/bin/env node` of tsup, vitest and tsc
          patchShebangs node_modules
          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild
          bun run build
          runHook postBuild
        '';

        # The npm tarball, ready for `npm publish ./result/foliag-zag-<version>.tgz`
        installPhase = ''
          runHook preInstall
          bun pm pack --destination $out
          runHook postInstall
        '';
      });
    };
}
