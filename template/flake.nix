{
  description = "Company server fleet built on nixos-fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    fleet.url = "github:4137314/nixos-fleet";
    fleet.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, fleet, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      nixosConfigurations = import ./fleet.nix { inherit nixpkgs fleet; };

      # nix run .#deploy -- web01 [switch|boot|test|dry-activate]
      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inventory = import ./inventory.nix;
          addresses = pkgs.writeText "addresses" (
            nixpkgs.lib.concatStrings (
              nixpkgs.lib.mapAttrsToList (name: host: "${name} ${host.address}\n") inventory.hosts
            )
          );
        in
        {
          deploy = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "deploy" ''
                set -euo pipefail
                host=''${1:?usage: deploy HOST [switch|boot|test|dry-activate]}
                action=''${2:-switch}
                address=$(${pkgs.gawk}/bin/awk -v h="$host" '$1 == h { print $2 }' ${addresses})
                [ -n "$address" ] || { echo "unknown host: $host" >&2; exit 2; }
                exec ${pkgs.nixos-rebuild-ng}/bin/nixos-rebuild "$action" --flake ".#$host" \
                  --target-host "${(import ./inventory.nix).deployUser}@$address" --sudo
              ''
            );
          };
        }
      );
    };
}
