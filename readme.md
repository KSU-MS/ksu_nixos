pre-reqs:

- for non-nixOs systems that have the nix package manager installed:
    - enable nix flakes (Better tutorial in the ksu_daq repo)
    - install `qemu-user-static qemu-user-binfmt qemu-user curl git` package then in `/etc/nix/nix.conf` add: 
        `extra-platforms = aarch64-linux arm-linux` 
        `trusted-users = root <your-user-here>`
        `sandbox = false`
    and restart
        `nix-daemon.service`


- to build the flake defined image: `nix build .#images.rpi --system aarch64-linux`

typical workflow:

1. build with either
    - `nix build .#images.rpi_top --system aarch64-linux`
2. `nix-copy-closure --to nixos@192.168.1.7 result/` (the output of this will have store path as part of output to switch to)
3. `ssh nixos@192.168.1.7` (password is nixos)
4. `sudo /nix/store/<hash-from-step-2>/bin/switch-to-configuration switch`
5. profit
