{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.fleet.base;
in
{
  options.fleet.base = {
    enable = lib.mkEnableOption "fleet defaults for unattended servers";
    environment = lib.mkOption {
      type = lib.types.enum [
        "production"
        "staging"
        "development"
      ];
      default = "production";
      description = "Exposed in /etc/fleet-environment and as a monitoring label.";
    };
    autoUpgrade = {
      enable = lib.mkEnableOption "unattended upgrades from the fleet flake";
      flake = lib.mkOption {
        type = lib.types.str;
        example = "github:acme/infrastructure";
        description = "Flake URI holding this host's configuration.";
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "04:00";
      };
      allowReboot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Reboot inside the maintenance window when the kernel changed.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = lib.mkDefault "UTC";
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        trusted-users = [ "@wheel" ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = lib.mkDefault "--delete-older-than 30d";
      };
    };

    system.autoUpgrade = lib.mkIf cfg.autoUpgrade.enable {
      enable = true;
      inherit (cfg.autoUpgrade) flake dates allowReboot;
      randomizedDelaySec = "45min";
      rebootWindow = lib.mkIf cfg.autoUpgrade.allowReboot {
        lower = "03:00";
        upper = "05:00";
      };
    };

    services.journald.settings.Journal = {
      SystemMaxUse = lib.mkDefault "1G";
      MaxRetentionSec = lib.mkDefault "3month";
    };
    services.fwupd.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    environment.etc."fleet-environment".text = cfg.environment + "\n";
    environment.systemPackages = with pkgs; [
      curl
      git
      htop
      jq
      lsof
      rsync
      tcpdump
      tmux
      vim
    ];
  };
}
