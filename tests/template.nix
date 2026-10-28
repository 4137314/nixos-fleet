# Evaluates every host of the template against this checkout and the deploy app.
{
  pkgs,
  self,
  nixpkgs,
}:
let
  hosts = import ../template/fleet.nix {
    inherit nixpkgs;
    fleet = self;
  };
in
pkgs.runCommand "nixos-fleet-template" { } ''
  ${pkgs.lib.concatStrings (
    pkgs.lib.mapAttrsToList (
      name: host:
      "echo ${name}: ${builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath}\n"
    ) hosts
  )}
  touch $out
''
