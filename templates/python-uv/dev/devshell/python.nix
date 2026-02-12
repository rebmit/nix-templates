# https://github.com/pyproject-nix/pyproject.nix/blob/d6c61dbe0be75e2f4cf0efcdc62428175be4cfb5/templates/impure/flake.nix
# https://github.com/cachix/devenv/blob/95d531cff33ce91cb028e3659f616c3ca3e99073/src/modules/languages/python/default.nix
{
  perSystem =
    { lib, pkgs, ... }:
    let
      libraries = pkgs.pythonManylinuxPackages.manylinux2014 ++ [
        pkgs.zstd
        pkgs.stdenv.cc.cc.lib
      ];

      makeWrapperArgs = [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        (lib.makeLibraryPath libraries)
      ];
    in
    {
      devshells.default = {
        commands = map (cmd: cmd // { category = "python"; }) [
          {
            package = pkgs.python3.buildEnv.override (args: {
              inherit makeWrapperArgs;
            });
          }
          { package = pkgs.uv; }
          { package = pkgs.ty; }
        ];
        env = [
          {
            name = "UV_PYTHON_PREFERENCE";
            value = "only-system";
          }
        ];
        devshell.startup.uv.text = ''
          unset PYTHONPATH
          uv sync
          . .venv/bin/activate
        '';
      };
    };
}
