# Fleet

Generated from [nixos-fleet](https://github.com/4137314/nixos-fleet).

1. Fill `inventory.nix` (hosts, operators, networks) and replace `hosts/*/default.nix` with real hardware configs.
2. Set up secrets (`secrets/README.md`).
3. First install: [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) or a NixOS ISO, then `nix run .#deploy -- <host>`.
4. Changes: open a PR, let CI run `nix flake check`, merge, deploy.
