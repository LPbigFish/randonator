{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          pkgs,
          ...
        }:
        let
          beamPackages_ = with pkgs.beamPackages; [
            elixir
            elixir-ls
            erlang
          ];
        in
        {
          devShells.default = pkgs.mkShell {

            packages = pkgs.lib.flatten (
              with pkgs;
              [
                beamPackages_
                inotify-tools
                # chrome-devtools MCP toolchain
                nodejs_22
                chromium
              ]
            );

            # Let chrome-devtools-mcp / puppeteer find the nix chromium
            PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
          };
        };
      flake = {
      };
    };
}
