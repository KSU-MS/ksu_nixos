{
  description = "Build image for KSU-MS's Pi running the ksu_daq flake and some other gizmos later";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixos-generators, nixpkgs, ... }@inputs:
    let
      flakeContext = {
        inherit inputs;
      };

    in {
      nixosModules = {
        # Core service things
        services = import ./modules/services.nix flakeContext;
        system = import ./modules/system.nix flakeContext;
        user-root = import ./modules/user-root.nix flakeContext;

        # Base DAQ utilities
        daq_service = import ./modules/data_acq.nix flakeContext;
        can_network = import ./modules/can_network.nix flakeContext;
      };

      packages = {
        aarch64-linux = {
          nixos = import ./packages/nixos.nix flakeContext;
        };
      };
    };
}
