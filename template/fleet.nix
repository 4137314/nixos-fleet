# Builds one nixosConfiguration per inventory host: shared defaults + roles + host file.
{ nixpkgs, fleet }:
let
  inventory = import ./inventory.nix;
in
nixpkgs.lib.mapAttrs (
  name: host:
  nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inventory host; };
    modules = [
      fleet.nixosModules.default
      ./roles/common.nix
      ./hosts/${name}
      {
        networking.hostName = name;
        nixpkgs.hostPlatform = host.system or "x86_64-linux";
      }
    ]
    ++ map (role: ./roles/${role}.nix) host.roles;
  }
) inventory.hosts
