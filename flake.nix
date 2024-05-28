{
  description = "Build image for KSU-MS's Pi running the ksu_daq flake and some other gizmos later";

  # Cache to reduce build times dont worry about it
  nixConfig = {
    extra-substituters = [ "https://raspberry-pi-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
    ];
  };

  # All the outside things to fetch from the internet
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c871670c7dad94b3454b8fc9a8a35e1ab92d8b3e";
    data_acq.url = "github:KSU-MS/ksu_daq";
    raspberry-pi-nix.url = "github:tstat/raspberry-pi-nix";
  };

  # All the things going into the generated image
  outputs = { self, nixpkgs, data_acq, raspberry-pi-nix }: rec {
    shared_config = {
      # Target architecture
      nixpkgs.hostPlatform.system = "aarch64-linux";

      # Overlays
      nixpkgs.overlays = [ (data_acq.overlays.default) ];

      # NTP time sync flag (network time protocol)
      services.timesyncd.enable = true;

      # User setup
      nix.settings.require-sigs = false;
      users.users.nixos.group = "nixos";
      users.users.root.initialPassword = "root";
      users.users.nixos.password = "nixos";
      users.users.nixos.extraGroups = [ "wheel" ];
      users.groups.nixos = { };
      users.users.nixos.isNormalUser = true;

      system.activationScripts.createRecordingsDir = nixpkgs.lib.stringAfter [ "users" ] ''
        mkdir -p /home/nixos/recordings
        chown nixos:users /home/nixos/recordings
      '';

      # Network settings
      networking.hostName = "Philipp";

      networking.firewall.enable = false;
      networking.useDHCP = false;

      # SSH settings
      services.openssh = { enable = true; };

      users.extraUsers.nixos.openssh.authorizedKeys.keys = [ ];

      systemd.services.sshd.wantedBy =
        nixpkgs.lib.mkOverride 40 [ "multi-user.target" ];

      # Git setup
      programs.git = {
        enable = true;
        config = {
          user.name = "";
          user.email = "";
        };
      };

      # Serial udev rule for xbee
      # services.udev.extraRules = ''
      #   KERNEL=="ttyUSB*", SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", SYMLINK+="xboi"
      #   # Identify
      #   # Find the ATTRS with this command
      #   # udevadm info --attribute-walk --name=/dev/*
      #   # Set perms
      #   # Symlink it for a consistant name
      # '';

    };

    # Config for can device
    can_config = {
      # Lol its just another network config
      networking = {
        can.enable = true;

        can.interfaces = {
          can0 = {
            bitrate = 1000000;
          };
        };
      };
    };

    pi_config = { pkgs, lib, ... }: {
      # More networking config
      networking = {
        interfaces.end0.ipv4.addresses = [{
          address = "192.168.1.7"; # Your static IP address
          prefixLength = 24; # Netmask, 24 for 255.255.255.0
        }];
        defaultGateway = "192.168.1.1";
      };
    };


    # shoutout to https://github.com/tstat/raspberry-pi-nix absolute goat
    nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./modules/data_acq.nix
        ./modules/can_network.nix
        (
          { pkgs, ... }: {
            config = {
              # Utils and other apps you want
              environment.systemPackages = with pkgs; [
                can-utils
                iperf3
              ];

              # Settings for the image that is generated
              sdImage.compressImage = false;
              raspberry-pi-nix.uboot.enable = false;

              # One shot systemd service to fix wacky fucking network bug
              systemd.services.restart-network-setup = {
                description = "Restart Network Setup Service";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-setup.service" ];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = "${pkgs.systemd}/bin/systemctl restart network-setup.service";
                  RemainAfterExit = true;
                };
              };
            };

            # Start the logging service
            options = {
              services.data_writer.options.enable = true;
            };
          }
        )

        # Getting the RPi firmware
        raspberry-pi-nix.nixosModules.raspberry-pi

        # Running the configs made earlier
        shared_config
        can_config
        pi_config
      ];
    };

    # Defineing the build commands for the terminal
    images.rpi_sd = nixosConfigurations.rpi.config.system.build.sdImage;
    images.rpi_top = nixosConfigurations.rpi.config.system.build.toplevel;
  };
}
