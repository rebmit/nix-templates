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
