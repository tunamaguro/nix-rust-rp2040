{ inputs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      package = config.packages."debug-elf";
      inherit (package.passthru) commonArgs cargoArtifacts craneLib;
      src = commonArgs.src;
      firmwareCheckArgs = commonArgs // { inherit cargoArtifacts; };
      checkArgs = firmwareCheckArgs // {
        CARGO_BUILD_TARGET = pkgs.stdenv.hostPlatform.rust.rustcTarget;
        cargoTestExtraArgs = "--lib";
      };
    in
    {
      checks = {
        # Building the default package also verifies ELF -> UF2 conversion.
        build = config.packages.default;

        fmt = craneLib.cargoFmt {
          inherit src;
        };

        clippy = craneLib.cargoClippy (
          firmwareCheckArgs
          // {
            cargoClippyExtraArgs = "-- --deny warnings";
          }
        );

        # Keep hardware-independent unit tests executable on the build host.
        test = craneLib.cargoTest checkArgs;

        audit = craneLib.cargoAudit {
          inherit src;
          advisory-db = inputs.advisory-db;
        };

        deny = craneLib.cargoDeny {
          inherit src;
        };
      };
    };
}
