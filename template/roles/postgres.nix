# PostgreSQL with a nightly logical dump included in the restic backup.
{ config, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "app" ];
    ensureUsers = [
      {
        name = "app";
        ensureDBOwnership = true;
      }
    ];
  };
  services.prometheus.exporters.postgres = {
    enable = true;
    runAsLocalSuperUser = true;
  };
  fleet.monitoring.extraPorts = [ config.services.prometheus.exporters.postgres.port ];
  fleet.backup.preBackup = ''
    install -d -m 700 -o postgres /var/lib/backup
    ${pkgs.util-linux}/bin/runuser -u postgres -- \
      ${config.services.postgresql.package}/bin/pg_dumpall > /var/lib/backup/postgres.sql
  '';
}
