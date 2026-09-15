{ inputs, ... }:
{
  perSystem =
    { config, lib, ... }:
    let
      package = config.packages."debug-elf";
      inherit (package.passthru) cargoArtifacts commonArgs craneLib;
      src = commonArgs.src;

      firmwareCheckArgs = commonArgs // { inherit cargoArtifacts; };

      hostCheckArgs = builtins.removeAttrs commonArgs [ "CARGO_BUILD_TARGET" ];
      hostCargoArtifacts = craneLib.buildDepsOnly (
        hostCheckArgs
        // {
          cargoExtraArgs = lib.escapeShellArgs [
            "--locked"
            "--workspace"
            "--lib"
            "--target"
            "host-tuple"
          ];
          doCheck = false;
        }
      );
      checkArgs = hostCheckArgs // {
        cargoArtifacts = hostCargoArtifacts;
        cargoTestExtraArgs = "--lib --target host-tuple";
        doCheck = true;
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
