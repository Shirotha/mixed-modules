{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
  };
  outputs =
    inputs@{ flake-parts, systems, ... }:
    with flake-parts.lib;
      mkFlake { inherit inputs; } {
        systems = import systems;

        imports = [
          flake-parts.flakeModules.flakeModules
        ];

        flake = args@{ lib, ... }:
          let
            local-lib = import ./lib.nix args;
          in {
            lib = local-lib;
            flakeModules = rec {
              module-system = importApply ./module-system local-lib;
              system-config = import ./system-config;
              default.imports = [ module-system system-config ];
            };
          };
      };
}
