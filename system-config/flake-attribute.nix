{ lib, ... }:
with lib;
{
  options.mixed-modules = {
    stateVersion = mkOption {
      type = types.str;
      default = "";
    };
    hostName = mkOption {
      type = types.functionTo types.str;
      default = id;
      defaultText = "id";
      description = ''
        function that maps logical host (as used in `.config.host.<host>`)
        to system host (as used in `nixosConfiguration.<host>`)
      '';
    };
    homeManagerModule = mkOption {
      type = types.nullOr<|types.uniq types.deferredModule;
      apply = x: if x == null then {} else x;
      default = null;
      description = "should be set to `inputs.home-mamager.nixosModule.home-manager`";
    };
    specialArgs = mkOption {
      type = types.attrs;
      default = {};
      description = "specialArgs passed to nixosSystem";
    };
    extraSpecialArgs = mkOption {
      type = types.attrs;
      default = {};
      description = "extraSpecialArgs passed to home-manager";
    };
  }; /* mixed-modules */
}
