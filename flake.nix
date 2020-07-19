{
  description = "Buildkite pipeline generation modules";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, ... }@inputs:
    let
      system = "x86_64-linux";
      systems = [ "x86_64-linux" ];
      nixpkgsFor = forAllSystems (system:
        (import inputs.nixpkgs {
          localSystem = { inherit system; };
          config = { allowUnfree = true; };
        }));
      forAllSystems = f: inputs.nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShell = forAllSystems
        (sys:
          let
            nixpkgs = nixpkgsFor.${sys};
          in
          import ./shell.nix { inherit nixpkgs; });
    };
}
