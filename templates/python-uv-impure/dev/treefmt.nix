{ lib, ... }:
let
  inherit (lib.meta) getExe;
in
{
  perSystem =
    { config, ... }:
    {
      treefmt = {
        flakeCheck = false;
        projectRootFile = "flake.nix";
        programs = {
          # keep-sorted start block=yes
          keep-sorted.enable = true;
          nixfmt.enable = true;
          prettier.enable = true;
          ruff-check.enable = true;
          ruff-format.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
          # keep-sorted end
        };
        settings = {
          global.excludes = [
            ".direnv/**"
            ".ruff_cache/**"
            "__pycache__/**"
            ".venv/**"
          ];
        };
      };

      pre-commit.settings.hooks.treefmt = {
        enable = true;
        name = "treefmt";
        entry = getExe config.treefmt.build.wrapper;
        pass_filenames = false;
      };
    };
}
