{
  lib,
  pkgs,
  crane,
  rustToolchainFor,
  cargoPackage ? null,
  profile ? "release",
  bin ? null,
  pname ? null,
  cargoBuildExtraArgs ? "",
  rustFlags ? null,
  doCheck ? false,
  dontStrip ? true,
}:
let
  target = "thumbv6m-none-eabi";
  craneLib = crane.overrideToolchain rustToolchainFor;
  rustToolchain = rustToolchainFor pkgs;

  commonArgs =
    {
      # Keep linker scripts and .cargo/config.toml in the Nix source. The
      # default Cargo-only source filter is too narrow for bare-metal builds.
      src = lib.cleanSource ../.;
      cargoLock = ../Cargo.lock;
      strictDeps = true;
      nativeBuildInputs = [ pkgs.flip-link ];

      CARGO_BUILD_TARGET = target;
      CARGO_PROFILE = profile;

      inherit doCheck dontStrip;
    }
    // lib.optionalAttrs (rustFlags != null) {
      RUSTFLAGS = rustFlags;
    };

  cargoArtifacts = craneLib.buildDepsOnly (
    commonArgs
    // {
      cargoExtraArgs = lib.escapeShellArgs [
        "--locked"
        "--workspace"
      ];
      inherit cargoBuildExtraArgs;
      doCheck = false;
    }
  );

  packageCargoExtraArgs = lib.escapeShellArgs (
    [ "--locked" ]
    ++ lib.optionals (cargoPackage != null) [
      "-p"
      cargoPackage
    ]
    ++ lib.optionals (bin != null) [
      "--bin"
      bin
    ]
  );

  crateInfo = craneLib.crateNameFromCargoToml {
    inherit (commonArgs) src;
  };

  resolvedPname =
    if pname != null then
      pname
    else if cargoPackage != null then
      cargoPackage
    else
      crateInfo.pname;

  resolvedMainProgram =
    if bin != null then
      bin
    else if cargoPackage != null then
      cargoPackage
    else
      crateInfo.pname;

  profileDir = if profile == "dev" then "debug" else profile;

  packageArgs =
    commonArgs
    // {
      inherit cargoArtifacts cargoBuildExtraArgs;
      pname = resolvedPname;
      cargoExtraArgs = packageCargoExtraArgs;
      installPhaseCommand = ''
        mkdir -p "$out/bin"
        cp "target/${target}/${profileDir}/${resolvedMainProgram}" "$out/bin/${resolvedMainProgram}"
      '';
    };
in
craneLib.buildPackage (
  packageArgs
  // {
    passthru = {
      inherit
        cargoArtifacts
        commonArgs
        craneLib
        rustToolchain
        target
        ;
      firmwareName = resolvedMainProgram;
    };
  }
)
