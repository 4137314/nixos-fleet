{ config, lib, ... }:
let
  cfg = config.fleet.hardening;
in
{
  options.fleet.hardening = {
    enable = lib.mkEnableOption "baseline server hardening (SSH, firewall, kernel, sudo)";
    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 22;
    };
    sshAllowedNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "10.0.0.0/8" ];
      description = "If non-empty, SSH is only reachable from these IPv4 CIDRs (IPv6 SSH is then dropped).";
    };
    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "Additional publicly reachable TCP ports.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
      openFirewall = cfg.sshAllowedNetworks == [ ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        AllowAgentForwarding = false;
        MaxAuthTries = 3;
        LoginGraceTime = 30;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };

    networking.firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = false;
      inherit (cfg) allowedTCPPorts;
      extraInputRules = lib.mkIf (cfg.sshAllowedNetworks != [ ]) ''
        ip saddr { ${lib.concatStringsSep ", " cfg.sshAllowedNetworks} } tcp dport ${toString cfg.sshPort} accept
      '';
    };
    networking.nftables.enable = true;

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
      bantime-increment.enable = true;
      ignoreIP = cfg.sshAllowedNetworks;
    };

    security.sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = lib.mkDefault false;
    };
    users.mutableUsers = false;

    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;
      "fs.suid_dumpable" = 0;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv4.tcp_syncookies" = 1;
    };
    boot.blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
      "firewire-core"
    ];
  };
}
