{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  # 
  imports = [
    inputs.self.nixosModules.services
    inputs.self.nixosModules.users
    inputs.self.nixosModules.can_network
    # inputs.self.nixosModules.daq_service
  ];

  config = {
    documentation = {
      enable = false;
    };

    # hardware = {
    #   enableRedistributableFirmware = {
    #     _type = "override";
    #     content = false;
    #     priority = 50;
    #   };
    #   firmware = [
    #     pkgs.raspberrypiWirelessFirmware
    #   ];
    # };

    networking = {
      hostName = "Phillipp";
      useDHCP = false;

      interfaces.end0.ipv4.addresses = [{
        address = "192.168.1.8"; # Your static IP address
        prefixLength = 24; # Netmask, 24 for 255.255.255.0
      }];
      defaultGateway = "192.168.1.1";

      can.enable = true;

      can.interfaces = {
        can0 = {
          bitrate = 500000;
        };
      };
    };
  };
}
