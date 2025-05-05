{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    # https://nixos.org/manual/nixos/stable/options.html search for systemd.services.<name>. to get list of all of the options for 
    # new systemd services
    systemd.services.data_writer = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.After = [ "network.target" ];
      # https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html serviceconfig
      serviceConfig.ExecStart =
        "${pkgs.py_data_acq_pkg}/bin/runner.py ${pkgs.proto_gen_pkg}/bin/ ${pkgs.can_pkg}";
      serviceConfig.ExecStop = "/bin/kill -SIGINT $MAINPID";
      serviceConfig.Restart = "on-failure";
    };
  };
}
