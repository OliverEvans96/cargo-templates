{
  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, fenix, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fenix-system = fenix.packages.${system};
        rust-toolchain = (with fenix-system;
          combine [
            default.toolchain
            {% if rust-analyzer %}
            complete.rust-src
            {% endif %}
          ]);
        rustPlatform = pkgs.makeRustPlatform {
          rustc = rust-toolchain;
          cargo = rust-toolchain;
        };
      in {
        defaultPackage = rustPlatform.buildRustPackage {
          pname = "{{project-name}}";
          version = "0.1.0";

          nativeBuildInputs = with pkgs; [ lld pkgconfig udev ];

          cargoLock = { lockFile = ./Cargo.lock; };

          src = ./.;
        };

        devShell = pkgs.mkShell {
          name = "{{project-name}}-shell";
          src = ./.;

          # build-time deps
          # from https://blog.thomasheartman.com/posts/bevy-getting-started-on-nixos
          nativeBuildInputs = (with pkgs; [
            rust-toolchain
            {% if rust-analyzer %}
            rust-analyzer
            {% endif %}

            lld
            pkgconfig
            udev
          ]);
        };
      });
}
