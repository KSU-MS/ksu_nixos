{ inputs, ... }@flakeContext:
let
  nixosModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.self.nixosModules.system
    ];
  };

in
inputs.nixos-generators.nixosGenerate {
  system = "aarch64-linux";
  format = "sd-aarch64";
  modules = [
    nixosModule
  ];
}

  boot = {
    loader = {
      grub.enable = false;
    };

    kernelPackages = pkgs.linuxPackagesFor pkgs.rpi-kernels.v6_12_17.bcm2712;
    # kernelPackages = pkgs.linuxPackages_rpi4;
    initrd.availableKernelModules = [
      "pcie_brcmstb" # required for the pcie bus to work
      "reset-raspberrypi" # required for vl805 firmware to load
      "usb_storage"
      "usbhid"
      "vc4"
    ];
  };

  environment = {
    etc."nixos".source = "/persistent/nixos";

    systemPackages = with pkgs; [
      nnn
      xplr
    ];
  };

  hardware.enableRedistributableFirmware = true;

  nixpkgs = {
    hostPlatform = "aarch64-linux";
    overlays = [ inputs.raspberry-pi-nix.overlays.core ];
  };

  nix.settings.flake-registry = "";

  raspberry-pi = {
    loader.enable = true;
  };
