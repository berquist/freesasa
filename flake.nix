{
  description = "Example C++ development environment for Zero to Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            pkgs = import nixpkgs { inherit system; };
          }
        );

      # pkgs-for-check = import (builtins.fetchGit {
      #   name = "pkgs-for-check";
      #   url = "https://github.com/NixOS/nixpkgs/";
      #   ref = "refs/heads/nixpkgs-unstable";
      #   # 0.15.0
      #   rev = "e296e89d75ab8aa1d0eed1c3688883a4f7937515";
      # }) { };

    in
    {
      devShells = forAllSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              autoconf
              automake
              check
              gcc
              json_c
              libxml2
              pkg-config

              bear
            ];
          };
        }
      );
    };
}
