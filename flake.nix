{
  description = "Build image for KSU-MS's Pi running the ksu_daq flake and some other gizmos later";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    daq_service.url = "github:KSU-MS/ksu_daq";
  };

  outputs = { self, nixos-generators, nixpkgs, daq_service, ... }@inputs:
    let
      flakeContext = {
        inherit inputs;
      };

    nixpkgs.overlays = [ (daq_service.overlays.default) ];

    in {
      nixosModules = {
        # Core service things
        services = import ./modules/services.nix flakeContext;
        system = import ./modules/system.nix flakeContext;
        users = import ./modules/users.nix flakeContext;

        # Base DAQ utilities
        daq_service = import ./modules/daq_service.nix flakeContext;
        can_network = import ./modules/can_network.nix flakeContext;
      };

      packages = {
        aarch64-linux = {
          nixos = import ./packages/nixos.nix flakeContext;
        };
      };
    };
}
