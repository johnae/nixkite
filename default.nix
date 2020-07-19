{ pipeline, specialArgs ? { }, pkgs ? import <nixpkgs> { } }:
let
  bklib = import ./lib;
  extendedLib = pkgs.lib.extend (self: super: bklib { lib = super; });

  sanitize =
    with pkgs;
    with extendedLib;
    configuration:
    builtins.getAttr (builtins.typeOf configuration) {
      bool = configuration;
      int = configuration;
      string = configuration;
      list = map sanitize configuration;
      set = mapAttrs
        (const sanitize)
        (filterAttrs (name: value: name != "_module" && value != null) configuration);
    };

  modules = with extendedLib;
    mapAttrsToList
      (name: _: ./modules + "/${name}")
      (
        filterAttrs
          (name: _: hasSuffix ".nix" name)
          (builtins.readDir ./modules)
      )
  ;

  result =
    extendedLib.evalModules {
      modules = modules ++ [
        pipeline
      ];
      args = { inherit pkgs; config = result.config; lib = extendedLib; };
      inherit specialArgs;
    };

  assertNoDuplicateKeys = with builtins; with extendedLib; s:
    let
      keys = filter
        (v: v != null)
        (map (s: if hasAttr "key" s then s.key else null) s);
      uniqueKeys = unique keys;
    in
    if (unique keys) == keys then s
    else
      let
        dupes = unique (filter (v: (count (lv: v == lv) keys) > 1) keys);
      in
      throw "step keys must be unique, these are used more than once: ${concatStringsSep ", " dupes}";

  steps = with extendedLib;
    assertNoDuplicateKeys (
      flatten (bk.attrs.snakeKeys (
        mapAttrsToList
          (k: v:
            (
              mapAttrsToList (k2: v2: v2) v
            ))
          (filterAttrs (name: _: name == "triggers" || name == "commands" || name == "inputs") (sanitize result.config).steps)
      ))
    );
in
{
  inherit steps;
}
