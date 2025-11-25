{
  inputs = {
    # keep-sorted start block=yes
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "parent/nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "parent/nixpkgs";
      inputs.gitignore.follows = "gitignore-nix";
      inputs.flake-compat.follows = "flake-compat";
    };
    gitignore-nix = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "parent/nixpkgs";
    };
    parent.url = ./../..;
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "parent/nixpkgs";
    };
    # keep-sorted end
  };

  outputs = _: { };
}
