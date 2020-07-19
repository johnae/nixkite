{ nixpkgs ? import <nixpkgs> { } }:
nixpkgs.mkShell {
  buildInputs =
    [ nixpkgs.nixFlakes ];
}
