{
  description = "Buildkite pipeline generation modules";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        nixpkgs = import inputs.nixpkgs {
          localSystem = { inherit system; };
        };
      in
      {
        devShell = import ./shell.nix { inherit nixpkgs; };
      }
    );
}
