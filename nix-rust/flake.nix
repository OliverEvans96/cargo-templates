{
  inputs = {
    {% if channel == "nightly" -%}
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    {% endif -%}
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, fenix, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        {% if channel == "nightly" -%}
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
        {% else -%}
        rustPlatform = pkgs.rustPlatform;
        {% endif -%}
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
          nativeBuildInputs = (with pkgs; [
            {% if channel == "nightly" -%}
            rust-toolchain
            {% else -%}
            rustc
            cargo
            {% endif -%}

            {% if rust-analyzer -%}
              {% if channel == "nightly" -%}
            fenix-system.rust-analyzer
              {% else -%}
            rust-analyzer
              {% endif -%}
            {% endif -%}

            lld
            pkgconfig
            udev
          ]);
        };
      });
}
