{
  perSystem =
    { config, ... }:
    let
      rustToolchain = config.packages."release-elf".passthru.rustToolchain;
    in
    {
      treefmt.programs = {
        rustfmt = {
          enable = true;
          package = rustToolchain;
          includes = [ "*.rs" ];
        };

        nixfmt = {
          enable = true;
          includes = [ "*.nix" ];
        };

        mdformat = {
          enable = true;
          includes = [ "*.md" ];
        };

        taplo = {
          enable = true;
          includes = [ "*.toml" ];
        };
      };
    };
}
