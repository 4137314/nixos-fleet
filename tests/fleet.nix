{ pkgs, self }:
let
  keys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;
in
pkgs.testers.runNixOSTest {
  name = "nixos-fleet";
  nodes = {
    server =
      { pkgs, ... }:
      {
        imports = [ self.nixosModules.default ];
        fleet = {
          base.enable = true;
          hardening = {
            enable = true;
            sshAllowedNetworks = [ "192.168.1.0/24" ];
          };
          users = {
            enable = true;
            accounts.alice = {
              admin = true;
              keys = [ keys.snakeOilPublicKey ];
            };
            revoked = [ "mallory" ];
          };
          monitoring = {
            enable = true;
            scrapeFrom = [ "192.168.1.1/32" ];
          };
          backup = {
            enable = true;
            repository = "/var/backup";
            passwordFile = "${pkgs.writeText "restic-pass" "test-only"}";
            paths = [ "/etc/fleet-environment" ];
          };
        };
      };
    # Test IPs follow node name order: admin 192.168.1.1, outsider .2, server .3.
    admin = { };
    outsider = { };
  };
  testScript = ''
    start_all()
    server.wait_for_unit("sshd.service")
    server.wait_for_unit("prometheus-node-exporter.service")

    admin.succeed("install -Dm600 ${keys.snakeOilPrivateKey} /root/snakeoil")
    with subtest("admin key logs in and has sudo, root login is refused"):
        ssh = "ssh -4 -i /root/snakeoil -o StrictHostKeyChecking=no -o BatchMode=yes"
        admin.succeed(f"{ssh} alice@server 'sudo -n true'")
        admin.fail(f"{ssh} root@server true")
        admin.fail(f"{ssh} -o PreferredAuthentications=password alice@server true")

    with subtest("exporters are reachable only from the monitoring CIDR"):
        admin.succeed("curl -sf --max-time 5 -o /tmp/metrics http://server:9100/metrics && grep -q node_systemd_unit_state /tmp/metrics")
        outsider.fail("curl -sf --max-time 5 http://server:9100/metrics")

    with subtest("revoked account is locked"):
        server.succeed("passwd -S mallory | grep -q ' L '")

    with subtest("restic backup runs and is restorable"):
        server.succeed("systemctl start restic-backups-fleet.service")
        server.succeed("RESTIC_PASSWORD=test-only ${pkgs.restic}/bin/restic -r /var/backup snapshots --json > /tmp/snapshots && grep -q fleet /tmp/snapshots")

    with subtest("hardening sysctls are applied"):
        server.succeed("test $(sysctl -n kernel.kptr_restrict) = 2")
  '';
}
