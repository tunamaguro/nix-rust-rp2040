{
  perSystem =
    { config, pkgs, ... }:
    let
      firmware = config.packages."debug-elf";
      rustToolchain = firmware.passthru.rustToolchain;
    in
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.attrValues config.checks ++ [ firmware ];
        packages = [
          rustToolchain
          config.treefmt.build.wrapper
          pkgs.picotool
          pkgs.flip-link
          pkgs.probe-rs-tools
        ];
      };
    };
}
