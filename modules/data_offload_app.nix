{ lib, pkgs, config, data_offload_app, ... }:

let
  # Shorter name to access final settings a 
  # user of hello.nix module HAS ACTUALLY SET.
  # cfg is a typical convention.
  cfg = config.services.data_offload_app;
in
{

  config = {
    # https://nixos.org/manual/nixos/stable/options.html search for systemd.services.<name>. to get list of all of the options for 
    # new systemd services
    systemd.services.data_offload_app = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig.WorkingDirectory = "${data_offload_app}";
      serviceConfig.ExecStart = "${pkgs.nodejs}/bin/npm start";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
