{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      openssh = {
        enable = true;
        openFirewall = true;
        passwordAuthentication = false;
      };
      transmission = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
