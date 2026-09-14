{ inputs, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    let
      mkPackage = import ../toolchain.nix { inherit inputs; };

      releaseElf = (mkPackage pkgs).override {
        profile = "release";
        dontStrip = false;
      };

      debugElf = (mkPackage pkgs).override {
        profile = "dev";
        dontStrip = true;
      };

      mkUf2 =
        name: elf:
        let
          mainProgram = elf.passthru.mainProgram;
        in
        pkgs.runCommand "${mainProgram}-${name}-uf2" { nativeBuildInputs = [ pkgs.elf2uf2-rs ]; } ''
          mkdir -p "$out"
          elf2uf2-rs convert --family rp2040 \
            "${elf}/bin/${mainProgram}" \
            "$out/${mainProgram}.uf2"
        '';

      debug = mkUf2 "debug" debugElf;
      release = mkUf2 "release" releaseElf;

      mkProbeRunner =
        name: elf:
        let
          mainProgram = elf.passthru.mainProgram;
        in
        pkgs.writeShellApplication {
          name = "probe-${name}";
          runtimeInputs = [ pkgs.probe-rs-tools ];
          text = ''
            exec probe-rs run --chip RP2040 --protocol swd "$@" \
              "${elf}/bin/${mainProgram}"
          '';
        };

      probeDebug = mkProbeRunner "debug" debugElf;
      probeRelease = mkProbeRunner "release" releaseElf;

      mkFlakeApp = package: {
        type = "app";
        program = lib.getExe package;
      };
    in
    {
      packages = {
        default = release;
        inherit debug release;
        "debug-elf" = debugElf;
        "release-elf" = releaseElf;
      };

      apps = {
        default = mkFlakeApp probeDebug;
        debug = mkFlakeApp probeDebug;
        release = mkFlakeApp probeRelease;
      };
    };
}
