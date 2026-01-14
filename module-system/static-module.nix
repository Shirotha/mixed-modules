{ lib, ... }:
with lib; {
  options = {
    lib = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      default = {};
      description = ''
        functions defined here will be availible in system and home modules
        via the `local-lib` argument
      '';
    };
    pkgs = mkOption {
      type = types.unspecified // {
        merge = loc: map (x: x.value);
      };
      default = {};
      apply = flatten;
      description = ''
        packages added here will be availible in system and home modules
        via the `local-pkgs` argument
      '';
    };
    host = mkOption {
      type = types.deferredModule;
      default = {};
      apply = flatten;
      description = ''
        options declared here will be availible in per host scope
        via `mixed-modules.config.host.<host>`
        or `mixed-modules.config.user.<user>.host`.

        these options will also be passed to system and home modules
        via the `host-config` argument
      '';
    };
    user = mkOption {
      type = types.deferredModule;
      default = {};
      apply = flatten;
      description = ''
        options declared here will be availible in per user scope
        via `mixed-modules.config.user.<user>`
        or `mixed-modules.config.host.<host>.user`.

        these options will also be passed to system and home modules
        via the `users-config` / `user-config` argument respectifly
      '';
    };
    system = mkOption {
      type = types.deferredModule;
      default = {};
      apply = flatten;
      description = "nixos system module";
    };
    home = mkOption {
      type = types.deferredModule;
      default = {};
      apply = flatten;
      description = "home manager module";
    };
  };
}
