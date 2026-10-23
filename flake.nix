{
  description = "FreeSASA: C library and command-line tool for solvent accessible surface area";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Build this checkout on top of the nixpkgs package, and add the
        # tests and documentation that the nixpkgs package leaves out.
        mkFreesasa =
          base:
          base.overrideAttrs (old: {
            version = "2.1.3";
            src = self;

            # The nixpkgs patch (upstream commit d5898c1) is already in this tree.
            patches = [ ];

            outputs = [
              "out"
              "doc"
            ];

            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.doxygen ];

            nativeCheckInputs = [
              # xmllint and jsonlint validate the CLI output in tests/test-cli.
              pkgs.libxml2.bin
              pkgs.python3Packages.demjson3
            ];

            checkInputs = [
              pkgs.check
              pkgs.subunit
            ];

            configureFlags = [
              "--enable-json"
              "--enable-xml"
              "--enable-doxygen"
              "--enable-check"
            ];

            # configure generates tests/test-cli with a #!/bin/bash shebang.
            postConfigure = ''
              patchShebangs tests/test-cli
            '';

            # The Doxygen HTML is built but not installed by doc/Makefile.am.
            postInstall = ''
              mkdir -p "$doc/share/doc/freesasa"
              cp -r doc/html "$doc/share/doc/freesasa/"
            '';

            doCheck = true;
            enableParallelBuilding = true;

            meta = old.meta // {
              homepage = "https://freesasa.github.io";
              changelog = "https://github.com/mittinatten/freesasa/blob/master/CHANGELOG.md";
            };
          });

        devPackages = [
          # Build system.
          pkgs.autoconf
          pkgs.automake
          pkgs.gnumake
          pkgs.pkg-config

          # Libraries.
          pkgs.json_c
          pkgs.libxml2
          pkgs.check
          pkgs.subunit

          # Test tools.
          pkgs.libxml2.bin
          pkgs.python3Packages.demjson3

          # Parser regeneration (--enable-parser-generator).
          pkgs.flex
          pkgs.bison

          # Documentation (--enable-doxygen).
          pkgs.doxygen

          # scripts/*.pl
          pkgs.perl

          # tests/compare-cif-pdb (F#).
          pkgs.dotnet-sdk

          # Coverage (--enable-gcov), debugging, and editor tooling.
          pkgs.lcov
          pkgs.gdb
          pkgs.valgrind
          pkgs.clang-tools
        ];

        mkDevShell =
          stdenv:
          (pkgs.mkShell.override { inherit stdenv; }) {
            packages = devPackages;
          };
      in
      {
        packages = {
          default = self.packages.${system}.freesasa;
          freesasa = mkFreesasa pkgs.freesasa;
          freesasa-clang = mkFreesasa (pkgs.freesasa.override { stdenv = pkgs.clangStdenv; });
        };

        devShells = {
          default = mkDevShell pkgs.stdenv;
          clang = mkDevShell pkgs.clangStdenv;
        };

        checks = {
          inherit (self.packages.${system}) freesasa freesasa-clang;
        };

        formatter = pkgs.nixfmt;
      }
    );
}
