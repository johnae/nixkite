{ config, pkgs, lib, ... }:
let
  cacheCmd = agents: {
    inherit agents;
    label = "Yay!";
    command = ''
      nix build
    '';
  };
in
with config.steps; {

  steps = {

    commands.cache-mac = cacheCmd { queue = "mac"; };
    commands.cache-linux = cacheCmd { queue = "linux"; };

    commands.docker.command = ''
      docker build -t docker/image:tag .
      docker push docker/image:tag
    '';

    commands.deploy-development = {
      dependsOn = [ commands.docker ];
      retry.automatic.limit = 2;
      command = ''
        do this
        do that
      '';
    };

    triggers.gitops = {
      trigger = "gitops";
      dependsOn = [
        commands.deploy-development
        "block" ## these can be either references to other steps or strings
      ];
    };

    inputs.block.input = "Continue with deployment?";
    inputs.block.fields = {
      textInput.thingie.text = "hello";
      textInput.thingie.hint = "The name for the release";
    };

  };

}
