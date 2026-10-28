{
  description = "Composable NixOS modules and a flake template for managing company server fleets";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules = {
        base = ./modules/base.nix;
        hardening = ./modules/hardening.nix;
        users = ./modules/users.nix;
        backup = ./modules/backup.nix;
        monitoring = ./modules/monitoring.nix;
        default = {
          imports = [
            ./modules/base.nix
            ./modules/hardening.nix
            ./modules/users.nix
            ./modules/backup.nix
            ./modules/monitoring.nix
          ];
        };
      };

      templates.default = {
        path = ./template;
        description = "Fleet repository: inventory, roles, per-host configs and deploy commands";
      };

      checks = forAllSystems (pkgs: {
        fleet = import ./tests/fleet.nix { inherit pkgs self; };
        template = import ./tests/template.nix { inherit pkgs self nixpkgs; };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
