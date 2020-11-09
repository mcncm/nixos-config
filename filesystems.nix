{ config, lib, pkgs, modulesPath, ... }:

{
  fileSystems."/backup" =
    { device = "/dev/disk/by-uuid/c432929a-f0ae-4d0b-b392-eee96f83dbac";
      # fsType = "ext4";
    };

  fileSystems."/data" =
    { device = "/dev/disk/by-uuid/0f66b8dd-14fe-473f-bf70-7fcc41d5b270";
      # fsType = "ext4";
    };

  users.groups.external-ssd = {
    # Is this guaranteed not to collide with anything?
    gid = 500;
    members = [ "mcncm" ];
  };
}
