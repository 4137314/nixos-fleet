# Single source of truth for hosts, roles and access. Edit this file, then deploy.
{
  deployUser = "deploy";
  environment = "production";
  monitoringServers = [ "10.0.10.5/32" ];
  adminNetworks = [ "10.0.0.0/8" ];

  operators = {
    deploy = {
      admin = true;
      keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithYourCiDeployKey deploy@ci" ];
    };
    alice = {
      admin = true;
      keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReplaceWithAliceKey alice@laptop" ];
    };
  };
  revokedOperators = [ ];

  hosts = {
    web01 = {
      address = "10.0.1.11";
      roles = [ "web" ];
    };
    db01 = {
      address = "10.0.2.21";
      roles = [ "postgres" ];
    };
  };
}
