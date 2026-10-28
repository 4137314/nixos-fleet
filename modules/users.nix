{ config, lib, ... }:
let
  cfg = config.fleet.users;
in
{
  options.fleet.users = {
    enable = lib.mkEnableOption "declarative operator accounts";
    accounts = lib.mkOption {
      description = "Operator accounts; only listed keys can log in.";
      default = { };
      example = lib.literalExpression ''
        {
          alice = { admin = true; keys = [ "ssh-ed25519 AAAA... alice@laptop" ]; };
          ci = { keys = [ "ssh-ed25519 AAAA... deploy" ]; groups = [ "deploy" ]; };
        }
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            admin = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Member of wheel (sudo).";
            };
            keys = lib.mkOption {
              type = lib.types.nonEmptyListOf lib.types.str;
              description = "Public SSH keys.";
            };
            groups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
    };
    revoked = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Former operators; their accounts are kept but locked and keyless.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.any (account: account.admin) (lib.attrValues cfg.accounts);
        message = "fleet.users: at least one admin account is required (root login is disabled).";
      }
      {
        assertion = lib.all (key: !(lib.hasPrefix "ssh-dss" key)) (
          lib.concatMap (account: account.keys) (lib.attrValues cfg.accounts)
        );
        message = "fleet.users: DSA keys are not allowed.";
      }
    ];
    users.groups = lib.genAttrs (lib.unique (
      lib.concatMap (account: account.groups) (lib.attrValues cfg.accounts)
    )) (_: { });
    users.users =
      lib.mapAttrs (_: account: {
        isNormalUser = true;
        extraGroups = account.groups ++ lib.optional account.admin "wheel";
        openssh.authorizedKeys.keys = account.keys;
      }) cfg.accounts
      // lib.genAttrs cfg.revoked (_: {
        isNormalUser = true;
        hashedPassword = "!";
        openssh.authorizedKeys.keys = lib.mkForce [ ];
      });
  };
}
