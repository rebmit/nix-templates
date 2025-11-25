# Portions of this file are sourced from
# https://github.com/pyproject-nix/pyproject.nix/blob/d6c61dbe0be75e2f4cf0efcdc62428175be4cfb5/flake.nix (MIT License)
{
  inputs = {
    nixpkgs.url = "github:rebmit/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
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
