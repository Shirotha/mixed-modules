{ lib, config, ... }:
with lib; with config.lib;
{
  lib.mkBoolOption =
    args: 
      {
        type = types.bool;
        default = false;
      }
     // args |> mkOption;

  pkgs =
    { pkgs, ... }:
    {
      hello = pkgs.hello;
    };

  host.main = mkBoolOption {};
  user = {
    admin = mkBoolOption {};
    owner = mkBoolOption {};
  };

  system =
    { lib, local-pkgs, users-config, ... }:
    with lib;
    {
      environment.systemPackages = [ local-pkgs.hello ];
      users.users = users-config|>mapAttrs (
        user: cfg: {
          description = user;
          group = user;
          isNormalUser = true;
          extraGroups = optional cfg.admin "wheel";
        });
    };

  home =
    { ... }:
    {
      # TODO: home manager example
    };
}
