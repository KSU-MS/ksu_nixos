{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    users = {
      users = {
        root = {
          openssh = {
            authorizedKeys = {
              keys = [
              ];
            };
          };
          password = "root";
        };
      };
    };
  };
}
