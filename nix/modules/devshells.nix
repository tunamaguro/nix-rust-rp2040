{
  perSystem =
    { config, pkgs, ... }:
    let
      firmware = config.packages."debug-elf";
    in
    {
      devShells.default = firmware.passthru.craneLib.devShell {
        checks = config.checks;
        inputsFrom = [ firmware ];
        packages = [
          config.treefmt.build.wrapper
          pkgs.picotool
          pkgs.flip-link
          pkgs.probe-rs-tools
        ];
      };
    };
}
