{ config, lib, ... }:
with lib;
let
  steps = config.steps;

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

  retryModule = types.submodule {
    options = {
      automatic = mkOption {
        type = with types; either bool (submodule {
          options = {
            exitStatus = mkOption {
              type = either ints.positive (enum [ "*" ]);
              default = "*";
            };
            limit = mkOption {
              type = nullOr ints.positive;
              default = null;
            };
          };
        });
        default = false;
      };
      manual = mkOption {
        type = with types; either bool (submodule {
          options = {
            allowed = mkOption {
              type = nullOr bool;
              default = null;
            };
            permitOnPassed = mkOption {
              type = nullOr bool;
              default = null;
            };
            reason = mkOption {
              type = nullOr str;
              default = null;
            };
          };
        });
        default = false;
      };
    };
  };

  coreOptions = name: {
    key = mkOption {
      type = with types; nullOr str;
      default = name;
    };
    dependsOn = mkOption {
      type = bk.types.uniqueKeys steps;
      #type = with types; with builtins;
      #  nullOr (
      #    coercedTo
      #      (listOf attrs)
      #      (x: map (s: if typeOf s == "string" then s else s.key) x)
      #      (listOf (enum (allKeys steps)))
      #  );
      default = null;
    };
    label = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    skip = mkOption {
      type = with types; nullOr (either bool str);
      default = null;
    };
    allowDependencyFailure = mkOption {
      type = with types; nullOr bool;
      defaultText = "Whether any of this steps dependencies are allowed to fail.";
      default = null;
    };
  };

  commandModule = with types; submodule ({ config, name, ... }: {
    options = with (coreOptions name); {
      inherit key dependsOn label skip allowDependencyFailure;
      retry = mkOption {
        type = with types; nullOr retryModule;
        default = null;
      };
      softFail = mkOption {
        type = with types; nullOr (either bool (listOf (submodule {
          options = {
            exitStatus = mkOption {
              type = ints.positive;
            };
          };
        }))
        );
        default = null;
      };
      timeoutInMinutes = mkOption {
        type = with types; nullOr ints.positive;
        default = null;
      };
      env = mkOption {
        type = with types; nullOr (attrsOf str);
        default = null;
      };
      parallelism = mkOption {
        type = with types; nullOr ints.positive;
        default = null;
      };
      plugins = mkOption {
        type = with types; nullOr (listOf attrs);
        default = null;
      };
      command = mkOption {
        type = with types; either (listOf str) str;
        defaultText = "Command(s) to run within this step.";
        description = ''
          The shell command/s to run during this step. This can be a single line of commands, or a list of commands that must all pass. Also available as the alias commands.
        '';
        example = literalExample ''
          command = \'\'
            echo hello > out.txt
            cat out.txt
          \'\';

          or:

          command = [
            "echo hello > out.txt"
            "cat out.txt"
          ];
        '';
      };
      agents = mkOption {
        type = with types; nullOr (attrsOf str);
        defaultText = "Agents(s) where this step should run.";
        default = null;
      };
      artifactPaths = mkOption {
        type = with types; nullOr (either (listOf str) str);
        default = null;
      };
      branches = mkOption {
        type = with types; nullOr str;
        default = null;
      };
      concurrency = mkOption {
        type = with types; nullOr ints.positive;
        default = null;
      };
      concurrencyGroup = mkOption {
        type = with types; nullOr str;
        default = null;
      };
    };
  });

  triggerModule = with types; submodule ({ config, name, ... }: {
    options = with (coreOptions name); {
      inherit key dependsOn label allowDependencyFailure;
      trigger = mkOption {
        type = types.str;
      };
      async = mkOption {
        type = with types; nullOr bool;
        default = null;
      };
      branches = mkOption {
        type = with types; nullOr str;
        default = null;
      };
      build = mkOption {
        type = with types; nullOr (submodule {
          options = {
            message = mkOption {
              type = nullOr str;
              default = null;
            };
            commit = mkOption {
              type = nullOr str;
              default = null;
            };
            branch = mkOption {
              type = nullOr str;
              default = null;
            };
            metaData = mkOption {
              type = nullOr (attrsOf str);
              default = null;
            };
            env = mkOption {
              type = nullOr (attrsOf str);
              default = null;
            };
          };
        });
        default = null;
      };
    };
  });

  textInputModule = with types; submodule ({ config, name, ... }: {
    options = {
      text = mkOption {
        type = nullOr str;
        default = null;
      };
      hint = mkOption {
        type = nullOr str;
        default = null;
      };
      required = mkOption {
        type = nullOr bool;
        default = null;
      };
      default = mkOption {
        type = nullOr str;
        default = null;
      };
      key = mkOption {
        type = str;
        default = name;
      };
    };
  });

  selectInputModule = with types; submodule ({ config, name, ... }: {
    options = {
      options = mkOption {
        ## yes the name is options as buildkite calls it that
        type = submodule {
          options = {
            label = mkOption {
              type = str;
            };
            value = mkOption {
              type = str;
            };
          };
        };
        default = null;
      };
      hint = mkOption {
        type = nullOr str;
        default = null;
      };
      required = mkOption {
        type = nullOr bool;
        default = null;
      };
      multiple = mkOption {
        type = nullOr bool;
        default = null;
      };
      default = mkOption {
        type = nullOr str;
        default = null;
      };
      key = mkOption {
        type = str;
        default = name;
      };
    };
  });

  inputModule = with types; submodule ({ config, name, ... }: {
    options = with (coreOptions name); {
      inherit key dependsOn label allowDependencyFailure;
      input = mkOption {
        type = str;
      };
      prompt = mkOption {
        type = nullOr str;
        default = null;
      };
      branches = mkOption {
        type = nullOr str;
        default = null;
      };
      fields = mkOption {
        apply = with lib; v:
          (
            mapAttrsToList
              (
                _: v:
                  (mapAttrsToList (_: v2: v2) v)
              )
              (filterAttrsRecursive (k: v: v != null) v)
          );
        type = submodule ({ config, name, ... }: {
          options = {
            textInput = mkOption {
              type = nullOr (attrsOf textInputModule);
              default = null;
            };
            selectInput = mkOption {
              type = nullOr (attrsOf selectInputModule);
              default = null;
            };
          };
        });
      };
    };
  });
in
{
  options.agents = mkOption {
    type = with types; nullOr (attrsOf str);
    default = null;
  };
  options.steps = {
    commands = mkOption {
      type = with types; nullOr (attrsOf commandModule);
      default = null;
    };

    triggers = mkOption {
      type = with types; nullOr (attrsOf triggerModule);
      default = null;
    };

    inputs = mkOption {
      type = with types; nullOr (attrsOf inputModule);
      default = null;
    };
  };
}
