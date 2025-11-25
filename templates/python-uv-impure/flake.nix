{
  description = "an impure Python project using uv";

  inputs = {
    rebmit.url = "github:rebmit/nix-exprs";
    flake-parts.follows = "rebmit/flake-parts";
    nixpkgs.follows = "rebmit/nixpkgs";
    import-tree.follows = "rebmit/import-tree";
  };

  outputs =
    inputs@{ flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ flake-parts.flakeModules.partitions ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      partitionedAttrs = {
        devShells = "dev";
        formatter = "dev";
      };

      partitions.dev = {
        extraInputsFlake = ./dev/_flake;
        module = import-tree ./dev;
      };
    };
}
