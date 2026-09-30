{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        # Node runs vite, vitest and tsup, and ships the npm CLI that publishes
        packages = [
          pkgs.bun
          pkgs.nodejs
        ];
      };
    };
}
