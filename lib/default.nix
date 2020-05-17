{ lib }:
with lib;
let
  allKeys = conf: flatten (
    mapAttrsToList
      (
        _: v:
          if v == null
          then [ ] else mapAttrsToList
            (
              _: s: if hasAttr "key" s && s.key != null then [ s.key ] else [ ]
            )
            v
      )
      conf
  );

  isAlpha = c: (toUpper c) != (toLower c);
  isUpper = c: (isAlpha c) && c == (toUpper c);
  isLower = c: !(isUpper c);
  toSnakeCase = s: concatStringsSep "" (
    concatMap
      (
        x:
        if isUpper x then [ "_" (toLower x) ] else [ x ]
      )
      (stringToCharacters s)
  );
  isSnakeCase = s: s == (toSnakeCase s);

  snakeKeys = with builtins; with lib; s:
    if typeOf s == "list"
    then
      map (snakeKeys) s
    else
      if typeOf s == "set"
      then
        mapAttrs' (n: v: nameValuePair (toSnakeCase n) v) s
      else s;
in
{
  bk = {
    strings = { inherit isAlpha isUpper isLower toSnakeCase isSnakeCase; };
    attrs = { inherit snakeKeys; };
    types =
      {
        uniqueKeys = with types; with builtins; steps:
          nullOr (
            coercedTo
              (listOf attrs)
              (x: map (s: if typeOf s == "string" then s else s.key) x)
              (listOf (enum (allKeys steps)))
          );
      };
  };
}
