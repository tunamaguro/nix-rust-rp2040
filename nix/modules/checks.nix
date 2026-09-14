{ inputs, ... }:
{
  perSystem =
    { config, ... }:
    let
      package = config.packages.debug;
      inherit (package.passthru) commonArgs cargoArtifacts craneLib;
      src = commonArgs.src;
      checkArgs = commonArgs // { inherit cargoArtifacts; };
    in
    {
      checks = {
        # Building the default package also verifies ELF -> UF2 conversion.
        build = config.packages.default;

        fmt = craneLib.cargoFmt {
          inherit src;
        };

        clippy = craneLib.cargoClippy (
          checkArgs
          // {
            cargoClippyExtraArgs = "--locked --lib --bin nix-rust-rp2040 -- --deny warnings";
          }
        );

        # Bare-metal firmware tests cannot be executed by the host. Keep host
        # unit tests in a separate crate/library if they are added later.
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
