{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    mixed-modules = {
      url = "path:./..";
      inputs.flake-parts.follows = "flake-parts";
    };
    systems.url = "github:nix-systems/default-linux";
  };
  outputs = inputs@{ nixpkgs, flake-parts, systems, home-manager, mixed-modules, ... }:
    with builtins; with nixpkgs.lib;
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      imports = [
        mixed-modules.flakeModule
      ];

      mixed-modules = {
        modules = ./modules|>readDir|>mapAttrsToList (mod: _: ./modules/${mod}) ;
        homeManagerModule = home-manager.nixosModules.home-manager;
        alternativeNixpkgs = nixpkgs;

        stateVersion = "25.11";
        hostName = toUpper;
        config = {
          shared.host.system = "x86_64-linux";
          user.userA.admin = true;
          host.hostA.main = true;
          special = {
            hostA.userA.owner = true;
            hostB.userA = {};
            hostB.userB.owner = true;
          };
        };
      };
    };
}
