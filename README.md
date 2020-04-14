### Nixkite: A Nix module for Buildkite pipelines

Buildkite is a flexible build system where the scheduler and UI is hosted but the agents are run by you. The agents are just standalone (go) binaries and there are agents for many operating systems and architectures, see: https://buildkite.com/docs/agent/v3/installation - you can also build it yourself as the agent is open source, see: https://github.com/buildkite/agent/.

Buildkite has a quite flexible scheduler which takes, as input, json or yaml. The different kinds of "steps" available can be found in the documentation here: https://buildkite.com/docs/pipelines.

Nix is a completely declarative and purely functional package manager, build system and programming language - Nix is the name for all three things. See: https://nixos.org/nix and https://nixos.org/ (for NixOS - the Linux Distribution).

Nix has a novel and very powerful module system for defining the configuration options for your system. This module system has been used elsewhere such as in [home-manager](https://github.com/rycee/home-manager), [terranix](https://terranix.org) (use Nix rather than HCL to write your terraform configuration), [kubenix](https://github.com/xtruder/kubenix) (use Nix to write your kubernetes specs rather than yaml) and many other similar projects.

Since I've used Buildkite for quite some time and I've already gone through two iterations of Buildkite pipeline generation written in Nix, I figured I should try using the Nix module system rather than "just functions". This is that project.

### Notes

This is a bit opinionated and it doesn't expose all of Buildkite's functionality. This is based on the relatively new functionality introduced in Buildkite where you give your steps keys which can then be depended on in other steps. This way your pipeline becomes a directed acyclic graph. So this means so far that wait steps are not supported and neither are block steps (input steps do the same thing though in a DAG world).

It is very early still and there may well be bugs. Still, I encourage you to try it out!

I'll write some usage instructions soon:ish, but this is what a pipeline looks like currently:

```nix
{ cfg, pkgs }:
with cfg; {

  steps = {

    commands.docker.command = ''
      docker build -t docker/image:tag .
      docker push docker/image:tag
    '';

    commands.deploy = {
      dependsOn = [ "docker" ];
      command = ''
        echo do this
        echo do that
      '';
    };

    triggers.other-pipeline = {
      trigger = "other-pipeline";
      dependsOn = [ "deploy" "block" ];
    };

    inputs.block.input = "Continue with deployment?";
    inputs.block.fields = {
      textInput.thingie.text = "hello";
      textInput.thingie.hint = "The name for the release";
    };

  };

}

```

And you'd output the Buildkite pipeline something like this (if the above existed in a file called `examples/pipeline.nix`):

```sh
nix-instantiate --eval --strict --json --argstr pipeline (pwd)/examples/pipeline.nix | jq .
```

Actually running the pipeline on Buildkite would instead look something like this (you'd run this on an agent):

```sh
nix-instantiate --eval --strict --json --argstr pipeline (pwd)/examples/pipeline.nix | \
    buildkite-agent pipeline upload --no-interpolation
````