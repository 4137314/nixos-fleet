{ config, lib, ... }:
let
  cfg = config.fleet.backup;
in
{
  options.fleet.backup = {
    enable = lib.mkEnableOption "nightly restic backups with retention";
    repository = lib.mkOption {
      type = lib.types.str;
      example = "s3:https://s3.eu-central-1.amazonaws.com/acme-backups/web01";
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to the repository password (e.g. a sops-nix or agenix secret).";
    };
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional credentials for the storage backend (AWS_ACCESS_KEY_ID=...).";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/etc"
        "/var/lib"
        "/home"
      ];
    };
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/var/lib/docker"
        "/var/lib/containers"
        "/var/lib/systemd/coredump"
        "**/.cache"
      ];
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "01:30";
    };
    retention = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
    preBackup = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "\${pkgs.postgresql}/bin/pg_dumpall -U postgres > /var/lib/backup/pg.sql";
      description = "Commands run before the snapshot, e.g. database dumps.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.fleet = {
      inherit (cfg)
        repository
        passwordFile
        environmentFile
        paths
        exclude
        ;
      initialize = true;
      extraBackupArgs = [
        "--tag"
        "fleet"
        "--exclude-caches"
        "--one-file-system"
      ];
      pruneOpts = cfg.retention;
      backupPrepareCommand = lib.mkIf (cfg.preBackup != "") cfg.preBackup;
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
  };
}
