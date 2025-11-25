{ inputs, ... }:
{
  imports = [
    # keep-sorted start
    inputs.devshell.flakeModule
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
    # keep-sorted end
  ];
}
