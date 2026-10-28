# Applied to every host.
{ inventory, ... }:
{
  fleet = {
    base = {
      enable = true;
      inherit (inventory) environment;
    };
    hardening = {
      enable = true;
      sshAllowedNetworks = inventory.adminNetworks;
    };
    users = {
      enable = true;
      accounts = inventory.operators;
      revoked = inventory.revokedOperators;
    };
    monitoring = {
      enable = true;
      scrapeFrom = inventory.monitoringServers;
    };
    backup = {
      enable = true;
      repository = "s3:https://s3.example.com/backups/${inventory.environment}";
      # Provide these with sops-nix or agenix; see README.
      passwordFile = "/run/secrets/restic-password";
      environmentFile = "/run/secrets/restic-env";
    };
  };
  system.stateVersion = "26.05";
}
