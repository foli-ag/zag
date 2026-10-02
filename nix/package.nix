{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      bun2nix = inputs.bun2nix.packages.${system}.default;

      # bun.lock is JSON with trailing commas, which builtins.fromJSON rejects
      lockfile = builtins.fromJSON (
        lib.concatMapStrings (part: if builtins.isList part then builtins.head part else part) (
          builtins.split ",([[:space:]]*[]}])" (builtins.readFile ../bun.lock)
        )
      );

      # The packages bun.lock pins, each fetched from npm with the integrity hash the lockfile records for it, in the
      # shape of the bun.nix that bun2nix's CLI generates. That CLI cannot read lockfile version 2, which bun 1.4
      # writes, so the lockfile is read here instead.
      lockedPackages =
        { fetchurl, ... }:
        lib.mapAttrs' (
          key: entry:
          let
            id = builtins.elemAt entry 0;
            parts = builtins.match "(@?[^@]+)@(.+)" id;
            name = builtins.elemAt parts 0;
            version = builtins.elemAt parts 1;
          in
          # A package from a workspace, a git repository or another registry has another shape
          assert lib.assertMsg (
            builtins.length entry == 4 && builtins.elemAt entry 1 == ""
          ) "bun.lock: ${key} is not a package from the npm registry";
          lib.nameValuePair id (fetchurl {
            url = "https://registry.npmjs.org/${name}/-/${baseNameOf name}-${version}.tgz";
            hash = builtins.elemAt entry 3;
          })
        ) lockfile.packages;
    in
    assert lib.assertMsg (lockfile.lockfileVersion == 2)
      "bun.lock: lockfile version ${toString lockfile.lockfileVersion} is not the one nix/package.nix reads";
    {
      packages.default = pkgs.stdenvNoCC.mkDerivation {
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

        # bun's install cache, holding every package bun.lock pins. The lockfile carries the hashes, so a dependency
        # change touches nothing here.
        bunDeps = bun2nix.fetchBunDeps {
          bunNix = lockedPackages;
          # Node runs vite, vitest, tsup and tsc, which are written for it, so their shebangs point at Node rather than
          # Bun
          useFakeNode = false;
        };

        # The hook runs `bun install` from that cache before the build, with the linker set in bunfig.toml
        nativeBuildInputs = [
          bun2nix.hook
          pkgs.nodejs
        ];
        bunInstallFlags = [
          "--frozen-lockfile"
        ]
        ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "--backend=symlink";
        # Only dependency lifecycle scripts would run, and the build needs none
        dontRunLifecycleScripts = true;

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
      };
    };
}
