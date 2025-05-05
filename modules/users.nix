{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    users = {
      groups.paul = {};

      users = {
        paul = {
          group = "paul";
          password = "paul";
          extraGroups = ["wheel"];
          isNormalUser = true;
        };

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

    system.activationScripts.createRecordingsDir = pkgs.lib.stringAfter [ "users" ] ''
      mkdir -p /home/paul/recordings
      chown paul:users /home/paul/recordings
    '';
  };
}
