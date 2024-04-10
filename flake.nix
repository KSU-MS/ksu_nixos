{
  description = "Build image";
  nixConfig = {
    extra-substituters = [ "https://raspberry-pi-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
    ];
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/8bf65f17d8070a0a490daf5f1c784b87ee73982c";
    data_acq.url = "github:KSU-MS/fg_daq/1622a8403abde90e577fe390a503ba829fbcb4e0";
    raspberry-pi-nix.url = "github:tstat/raspberry-pi-nix";

  };
  outputs = { self, nixpkgs, data_acq, raspberry-pi-nix }: rec {

    shared_config = {
      nixpkgs.overlays = [ (data_acq.overlays.default) ];

      # nixpkgs.config.allowUnsupportedSystem = true;
      nixpkgs.hostPlatform.system = "aarch64-linux";

      # Docker setup
      virtualisation.docker.enable = true;
      users.users.nixos.extraGroups = [ "docker" ];
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      # networking/SSH
      systemd.services.sshd.wantedBy =
        nixpkgs.lib.mkOverride 40 [ "multi-user.target" ];

      services.openssh = { enable = true; };
      services.openssh.listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22;
        }
        {
          addr = ":";
          port = 22;
        }
      ];

      users.extraUsers.nixos.openssh.authorizedKeys.keys = [ ];
      networking.useDHCP = false;
      networking.firewall.enable = false;
      networking.wireless = {
        enable = true;
        interfaces = [ "wlan0" ];
        networks = { "KSUDQ" = { psk = "k18E206!"; }; };
      };

      networking.interfaces.wlan0.ipv4.addresses = [{
        address = "192.168.1.120";
        prefixLength = 24;
      }];

      # networking.interfaces.end0.ipv4 = {
      #   addresses = [
      #     {
      #       address = "192.168.1.100"; # Your static IP address
      #       prefixLength = 24; # Netmask, 24 for 255.255.255.0
      #     }
      #   ];
      #   routes = [
      #     {
      #       address = "0.0.0.0";
      #       prefixLength = 0;
      #       via = "192.168.1.1"; # Your gateway IP address
      #     }
      #   ];
      # };
      networking.nameservers = [ "192.168.1.1" ]; # Your DNS server, often the gateway

      systemd.services.wpa_supplicant.wantedBy =
        nixpkgs.lib.mkOverride 10 [ "default.target" ];
      # NTP time sync.
      services.timesyncd.enable = true;
      programs.git = {
        enable = true;
        config = {
          user.name = "";
          user.email = "";
        };
      };

      # Serial udev rule for xbee
      services.udev.extraRules = ''
        KERNEL=="ttyUSB*", SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", SYMLINK+="xboi"
        # Identify
        # Find the ATTRS with this command
        # udevadm info --attribute-walk --name=/dev/*
        # Set perms
        # Symlink it for a consistant name
      '';

      # Config for can device
      # can_config = {
      #   networking.can.enable = true;
      #
      #   networking.can.interfaces = {
      #     can0 = {
      #       bitrate = 500000;
      #     };
      #   };
      # };
    };

    pi_config = { pkgs, lib, ... }:
      {
        nix.settings.require-sigs = false;
        users.users.nixos.group = "nixos";
        users.users.root.initialPassword = "root";
        users.users.nixos.password = "nixos";
        users.users.nixos.extraGroups = [ "wheel" ];
        users.groups.nixos = { };
        users.users.nixos.isNormalUser = true;

        system.activationScripts.createRecordingsDir = lib.stringAfter [ "users" ] ''
          mkdir -p /home/nixos/recordings
          chown nixos:users /home/nixos/recordings
        '';

        hardware = {
          bluetooth.enable = true;
          raspberry-pi = {
            config = {
              all = {
                base-dt-params = {
                  #           # enable autoprobing of bluetooth driver
                  #           # https://github.com/raspberrypi/linux/blob/c8c99191e1419062ac8b668956d19e788865912a/arch/arm/boot/dts/overlays/README#L222-L224
                  krnbt = {
                    enable = true;
                    value = "on";
                  };
                  spi = {
                    enable = true;
                    value = "on";
                  };
                };
                dt-overlays = {
                  spi-bcm2835 = {
                    enable = true;
                    params = { };
                  };

                  # TODO: change this as needed
                  # mcp2515-can0 = {
                  #   enable = true;
                  #   params = {
                  #     oscillator =
                  #       {
                  #         enable = true;
                  #         value = "16000000";
                  #       };
                  #     interrupt = {
                  #       enable = true;
                  #       value = "16"; # this is the individual gpio number for the interrupt of the spi boi
                  #     };
                  #   };
                  # };
                };
              };
            };
          };
        };
      };


    # shoutout to https://github.com/tstat/raspberry-pi-nix absolute goat
    nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./modules/data_acq.nix
        # ./modules/can_network.nix
        (
          { pkgs, ... }: {
            config = {
              environment.systemPackages = [
                pkgs.can-utils
              ];
              environment.variables = {
                D_SOURCE = "SERIAL";
              };
              sdImage.compressImage = false;
            };
            options = {
              services.data_writer.options.enable = true;
            };
          }
        )
        # (can_config)
        (shared_config)
        raspberry-pi-nix.nixosModules.raspberry-pi
        pi_config
      ];
    };

    images.rpi = nixosConfigurations.rpi.config.system.build.sdImage;
    defaultPackage.aarch64-linux = nixosConfigurations.rpi4.config.system.build.toplevel;
  };
}
