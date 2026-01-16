{ local-lib, cfg }:
{ lib, ... }:
with lib; with local-lib;
let
  scopedModule = types'.scopedModule { inherit (cfg) host user; };
in {
  options.mixed-modules = {
    config = {
      shared = mkOption {
        type = types.deferredModule;
        apply = applyScopedModules {};
        default = {};
        description = "options defined here will apply to all hosts";
      };
      host = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        apply = mapAttrs (host: applyScopedModules { default = "host"; });
        default = {};
        description = "options defined here will apply to a specific host";
      };
      user = mkOption {
        type = types.lazyAttrsOf types.deferredModule;
        apply = mapAttrs (user: applyScopedModules { default = "user"; });
        default = {};
        description = "options defined here will apply to a specific user";
      };
      special = mkOption {
        type = types.lazyAttrsOf<|types.lazyAttrsOf types.deferredModule;
        apply = nestedMapAttrs 2 (host: user: applyScopedModules { default = "user"; });
        default = {};
        description = ''
          options defined here will apply to a specific host, user combination

          a config will only be generated for combinations that are listedd here
        '';
      };
    }; /* config */
    modules = mkOption {
      type = types.listOf types.deferredModule;
      default = [];
    };
    alternativeNixpkgs = mkOption {
      type = types.unspecified;
      default = null;
      description = "alternative nixpkgs repository, availible in modules as pkgs'";
    };
    staging = {
      lib = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = {};
      };
      pkgs = mkOption {
        type = types.lazyAttrsOf<|types.lazyAttrsOf types.unspecified;
        default = {};
      };
      config = mkOption {
        type = scopedModule;
        default = {};
      };
      systemModules = mkOption {
        type = types.listOf types.deferredModule;
        default = {};
      };
      homeModules = mkOption {
        type = types.listOf types.deferredModule;
        default = {};
      };
    }; /* staging */
  }; /* mixed-modules */
}
