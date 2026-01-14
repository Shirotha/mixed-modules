local-lib:
{ lib, config, inputs, withSystem, ... }:
with lib; with local-lib; with inputs.flake-parts.lib;
let
  result = evalModules {
    modules = [ ./static-module.nix ]
      ++ config.mixed-modules.modules;
  };
  cfg = result.config;
in {
  imports = singleton<|importApply ./flake-attribute.nix { inherit local-lib cfg; };

  mixed-modules.staging = {
    inherit (cfg) lib;
    pkgs = genAttrs (import inputs.systems) (system: withSystem system (
      { pkgs, ... }:
        let
          args = { inherit pkgs final; };
          apply = mod:
            if isFunction mod
            then mod args
            else if isPath mod
              then apply<|import mod
              else mod;
          merge = xs: x: attrsets.unionOfDisjoint xs (apply x);
          final = foldl' merge {} cfg.pkgs;
        in final
      ));
    config = mergeScopedModules config.mixed-modules.config;
    systemModules = cfg.system;
    homeModules = cfg.home;
  };
}
