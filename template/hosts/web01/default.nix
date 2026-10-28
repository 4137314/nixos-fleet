# Host-specific settings. Replace with the output of `nixos-generate-config --show-hardware-config`.
{ ... }:
{
  boot.loader.grub.device = "/dev/sda";
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
