# nixos-fleet

Composable NixOS modules and a ready-to-fork repository template for running **company server fleets** on NixOS: hardened SSH, declarative operator access with revocation, scoped monitoring, and restic backups. Everything is covered by a multi-machine NixOS VM test.

```bash
nix flake init -t github:4137314/nixos-fleet   # new fleet repository
$EDITOR inventory.nix                           # hosts, roles, operators, networks
nix run .#deploy -- web01                       # nixos-rebuild over SSH
```

## Modules

Import everything with `nixosModules.default`, or pick individual modules. Every module stays inert until you set `enable`.

| Module | Options | What it does |
| --- | --- | --- |
| `base` | `fleet.base.*` | Flakes, weekly GC, bounded journald, admin tools, `/etc/fleet-environment`, optional `system.autoUpgrade` from your fleet flake with a reboot window |
| `hardening` | `fleet.hardening.*` | Key-only SSH, no root login, nftables default-deny, SSH restricted to admin CIDRs, fail2ban, kernel sysctls, uncommon protocols blacklisted, immutable users |
| `users` | `fleet.users.accounts`, `.revoked` | Operators with keys, sudo via `admin = true`, extra groups. Revoked accounts are kept for audit and locked. Assertions forbid DSA keys and fleets without an admin |
| `monitoring` | `fleet.monitoring.scrapeFrom` | node_exporter + systemd exporter, reachable **only** from Prometheus CIDRs (`extraPorts` for other exporters) |
| `backup` | `fleet.backup.*` | restic to S3/B2/SFTP/REST with retention, `preBackup` hook for DB dumps, randomized nightly timer |

```nix
{
  imports = [ inputs.fleet.nixosModules.default ];
  fleet = {
    base.enable = true;
    hardening = { enable = true; sshAllowedNetworks = [ "10.0.0.0/8" ]; };
    users = {
      enable = true;
      accounts.alice = { admin = true; keys = [ "ssh-ed25519 AAAA... alice" ]; };
      revoked = [ "bob" ];
    };
    monitoring = { enable = true; scrapeFrom = [ "10.0.10.5/32" ]; };
    backup = {
      enable = true;
      repository = "s3:https://s3.eu-central-1.amazonaws.com/acme-backups/web01";
      passwordFile = "/run/secrets/restic-password";
    };
  };
}
```

## Template layout

```
inventory.nix      single source of truth: hosts, addresses, roles, operators, networks
fleet.nix          builds one nixosConfiguration per host (defaults + roles + host file)
roles/common.nix   applied everywhere (wires inventory into fleet.* options)
roles/web.nix      nginx + ACME reverse proxy
roles/postgres.nix PostgreSQL + exporter + dump before every backup
hosts/<name>/      hardware and host-specific settings
secrets/           sops-nix/agenix guidance (no secrets in the Nix store)
```

Onboarding a new admin means adding their key to `inventory.nix` and deploying. Offboarding means moving their name to `revokedOperators`. Both changes are visible and reviewable in Git.

## Works with

- [ops-toolkit](https://github.com/4137314/ops-toolkit): certificate, backup and SSH-key checks exported to node_exporter.
- [observability-stack](https://github.com/4137314/observability-stack): Prometheus/Alertmanager/Grafana with alert rules for these hosts.
- [ansible-baseline](https://github.com/4137314/ansible-baseline): the same baseline for Debian/RHEL hosts that are not on NixOS yet.

## Development

```bash
nix flake check -L   # multi-VM test (SSH, sudo, firewall scoping, revocation, backup) + template evaluation
```

## License

MIT. Migrating servers to NixOS or standardizing an existing fleet? Open an issue or contact me via [GitHub](https://github.com/4137314).
