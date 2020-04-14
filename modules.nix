{ config, lib, ... }:

with lib;

{
  imports = mapAttrsToList (
    name: _: ./modules + "/${name}"
  )
    (
      filterAttrs
        (name: _: hasSuffix ".nix" name)
        (builtins.readDir ./modules)
    );
}
