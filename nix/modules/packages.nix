{ inputs, ... }:
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mkPackage = import ../toolchain.nix { inherit inputs; };
      firmwareName = "nix-rust-rp2040";

      release = (mkPackage pkgs).override {
        profile = "release";
        dontStrip = true;
      };

      debug = (mkPackage pkgs).override {
        profile = "dev";
        dontStrip = true;
      };

      mkUf2 =
        name: elf:
        pkgs.runCommand "${firmwareName}-${name}-uf2" { nativeBuildInputs = [ pkgs.elf2uf2-rs ]; } ''
          mkdir -p "$out"
          elf2uf2-rs convert --family rp2040 \
            "${elf}/bin/${firmwareName}" \
            "$out/${firmwareName}.uf2"
        '';

      releaseUf2 = mkUf2 "release" release;
      debugUf2 = mkUf2 "debug" debug;

      mkProbeRunner =
        name: elf:
        pkgs.writeShellApplication {
          name = "probe-${name}";
          runtimeInputs = [ pkgs.probe-rs-tools ];
          text = ''
            exec probe-rs run --chip RP2040 --protocol swd "$@" \
              "${elf}/bin/${firmwareName}"
          '';
        };

      probeDebug = mkProbeRunner "debug" debug;
      probeRelease = mkProbeRunner "release" release;

      mkFlakeApp = package: {
        type = "app";
        program = lib.getExe package;
      };
    in
    {
      packages = {
        default = releaseUf2;
        uf2 = releaseUf2;
        "debug-uf2" = debugUf2;
        elf = release;
        inherit debug release;
      };

      apps = {
        default = mkFlakeApp probeDebug;
        debug = mkFlakeApp probeDebug;
        release = mkFlakeApp probeRelease;
      };
    };
}
