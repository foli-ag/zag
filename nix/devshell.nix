{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.nodejs
          pkgs.pnpm
        ];
      };
    };
}
