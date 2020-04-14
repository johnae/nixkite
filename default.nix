{ pipeline }:
let
  pkgs = import <nixpkgs> { };

  stringHelpers = with builtins; with pkgs.lib;
    rec {
      isAlpha = c: (toUpper c) != (toLower c);
      isUpper = c: (isAlpha c) && c == (toUpper c);
      isLower = c: !(isUpper c);
      toSnakeCase = s: concatStringsSep "" (
        concatMap (
          x:
          if isUpper x then [ "_" (toLower x) ] else [ x ]
        ) (stringToCharacters s)
      );
      isSnakeCase = s: s == (toSnakeCase s);
    };

  sanitize =
    with pkgs;
    configuration:
    builtins.getAttr (builtins.typeOf configuration) {
      bool = configuration;
      int = configuration;
      string = configuration;
      list = map sanitize configuration;
      set = lib.mapAttrs
        (lib.const sanitize)
        (lib.filterAttrs (name: value: name != "_module" && value != null) configuration);
    };

  config = import pipeline { inherit pkgs; cfg = result.config; };

  result =
    with pkgs;
    with lib;
    evalModules {
      modules = [
        ./modules.nix
        config
      ];
    };

  snakeKeys = with builtins; with pkgs.lib; with stringHelpers; s:
    if typeOf s == "list"
    then
      map (snakeKeys) s
    else
      if typeOf s == "set"
      then
        mapAttrs' (n: v: nameValuePair (toSnakeCase n) v) s
      else s;

  ensureNoDuplicateKeys = with builtins; with pkgs.lib; s:
    let
      keys = filter (v: v != null)
        (map (s: if hasAttr "key" s then s.key else null) s);
      uniqueKeys = unique keys;
    in
      if (unique keys) == keys then s
      else
        let
          dupes = unique (filter (v: (count (lv: v == lv) keys) > 1) keys);
        in
          throw "step keys must be unique, these are used more than once: ${concatStringsSep ", " dupes}";

  steps = with pkgs.lib;
    ensureNoDuplicateKeys (flatten
      (snakeKeys (
        mapAttrsToList
          (k: v:
            (
              mapAttrsToList (k2: v2: v2) v
            )) (sanitize result.config).steps
      )));
in
{
  inherit steps;
}
