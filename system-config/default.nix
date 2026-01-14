{ config, lib, inputs, withSystem, ... }:
with lib;
let
  cfg = config.mixed-modules;
in {
  imports = [ ./flake-attribute.nix ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };

  flake =
    let
      common_args = {
        inherit system inputs';
        local-lib = cfg.staging.lib;
      };
    in {
      debug-cfg = cfg;
      nixosConfigurations = cfg.staging.config.host|>mapAttrs' (host: host-config:
        withSystem host-config.system (
          { system, pkgs, ... }:
          let
            hostName = cfg.hostName host;
            local-pkgs = cfg.staging.pkgs.${system};
            specialArgs = common_args // {
                inherit host-config local-pkgs;
                users-config = cfg.staging.config.user.${host};
              } // cfg.specialArgs;
            extraSpecialArgs = common_args // {
                inherit host-config local-pkgs;
              } // cfg.extraSpecialArgs;
          in {
            name = hostName;
            value = lib.nixosSystem {
              inherit specialArgs;
              modules = cfg.staging.systemModules
                ++ [
                    inputs.nixpkgs.nixosModules.readOnlyPkgs
                    {
                      nixpkgs = { inherit pkgs; };
                      networking = { inherit hostName; };
                      system = { inherit (cfg) stateVersion; };
                    }
                  ]
                ++ optionals (cfg.homeManagerModule != null) [
                  cfg.homeManagerModule
                  { home-manager = {
                    inherit extraSpecialArgs;
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    users = cfg.staging.config.user.${host}|>mapAttrs (user: user-config: {
                      imports = cfg.staging.homeModules
                        ++ [{
                            _module.args = { inherit user-config; };
                          }];
                      home = {
                        inherit (cfg) stateVersion;
                        username = mkDefault user;
                        homeDirectory = mkDefault "/home/${user}";
                      };
                    }); /* users */
                    backupFileExtension = "bak";
                  };}]; /* home-manager, modules */
            }; /* value */
          })); /* nixosConfigurations, withSystem */
    };
}
