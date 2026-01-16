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

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs' =
        let
          nixpkgs' = config.mixed-modules.alternativeNixpkgs;
        in mkIf (nixpkgs' != null) (
          import config.mixed-modules.alternativeNixpkgs {
            inherit system;
            config.allowUnfree = true;
          });
    };

  mixed-modules.staging = {
    inherit (cfg) lib;
    pkgs = genAttrs (import inputs.systems) (system: withSystem system (
      { pkgs, pkgs', ... }:
        let
          args = { inherit pkgs pkgs' final; };
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
