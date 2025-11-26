# Portions of this file are sourced from
# https://github.com/pyproject-nix/pyproject.nix/blob/d6c61dbe0be75e2f4cf0efcdc62428175be4cfb5/templates/impure/flake.nix (MIT License)
{
  perSystem =
    { lib, pkgs, ... }:
    {
      devshells.default = {
        commands = map (cmd: cmd // { category = "python"; }) [
          { package = pkgs.python3; }
          { package = pkgs.uv; }
          { package = pkgs.ty; }
        ];
        env = [
          {
            name = "PYTHONPATH";
            unset = true;
          }
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          {
            name = "LD_LIBRARY_PATH";
            value = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
          }
        ];
        devshell.startup.uv.text = ''
          uv sync
          . .venv/bin/activate
        '';
      };
    };
}
