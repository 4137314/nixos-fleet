Keep secrets out of the Nix store. Recommended: [sops-nix](https://github.com/Mic92/sops-nix)
with one age key per host (derived from its SSH host key), decrypted to `/run/secrets/*`.
The backup role expects `/run/secrets/restic-password` and `/run/secrets/restic-env`.
