{ config, lib, ... }:
let
  cfg = config.fleet.monitoring;
  ports = [
    config.services.prometheus.exporters.node.port
    config.services.prometheus.exporters.systemd.port
  ]
  ++ cfg.extraPorts;
in
{
  options.fleet.monitoring = {
    enable = lib.mkEnableOption "node and systemd exporters reachable only from the monitoring network";
    scrapeFrom = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      example = [ "10.0.10.5/32" ];
      description = "IPv4 CIDRs of the Prometheus servers allowed to scrape this host.";
    };
    extraPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "Additional exporter ports (e.g. postgres_exporter) opened to scrapeFrom.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
      systemd.enable = true;
    };
    networking.firewall.extraInputRules = ''
      ip saddr { ${lib.concatStringsSep ", " cfg.scrapeFrom} } tcp dport { ${
        lib.concatMapStringsSep ", " toString ports
      } } accept
    '';
    networking.nftables.enable = true;
  };
}
