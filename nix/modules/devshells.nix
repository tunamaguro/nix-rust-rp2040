{
  perSystem =
    { config, pkgs, ... }:
    let
      firmware = config.packages.debug;
    in
    {
      devShells.default = firmware.passthru.craneLib.devShell {
        checks = config.checks;
        inputsFrom = [ firmware ];
        packages = [
          config.treefmt.build.wrapper
          pkgs.elf2uf2-rs
          pkgs.flip-link
          pkgs.probe-rs-tools
        ];
      };
    };
}
