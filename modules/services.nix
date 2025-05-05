{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    services = {
      openssh = {
        enable = true;
        openFirewall = true;
        settings.PasswordAuthentication = true;
      };
      
      transmission = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}
