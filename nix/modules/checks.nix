{ inputs, ... }:
{
  perSystem =
    { config, ... }:
    let
      package = config.packages."debug-elf";
      inherit (package.passthru) cargoArtifacts commonArgs craneLib;
      src = commonArgs.src;

      firmwareCheckArgs = commonArgs // { inherit cargoArtifacts; };

      hostCheckArgs = commonArgs // {
        CARGO_BUILD_TARGET = "host-tuple";
        doCheck = true;
      };
      hostCargoArtifacts = craneLib.buildDepsOnly hostCheckArgs;
      checkArgs = hostCheckArgs // {
        cargoArtifacts = hostCargoArtifacts;
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
