{
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
  };

  outputs =
    { nixpkgs-lib, ... }:
    let
      inherit (nixpkgs-lib) lib;
    in
    {
      templates =
        let
          root = ./templates;
          dirs = lib.pipe root [
            builtins.readDir
            (lib.filterAttrs (_: type: type == "directory"))
            lib.attrNames
          ];
        in
        lib.listToAttrs (
          map (
            dir:
            let
              path = root + "/${dir}";
              template = import (path + "/flake.nix");
            in
            lib.nameValuePair dir {
              inherit path;
              inherit (template) description;
            }
          ) dirs
        );
    };
}
