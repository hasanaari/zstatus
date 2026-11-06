{
  description = "zstatus";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";

    zig = {
      url = "github:silversquirl/zig-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls = {
      url = "github:zigtools/zls/0.17.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-flake.follows = "zig";
    };
  };

  outputs = inputs: let
    inherit (inputs) nixpkgs;

    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            zig = inputs.zig.packages.${system}.zig_0_17_0;
            zls = inputs.zls.packages.${system}.default;
          })
        ];
      });
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [zig zls];
      };
    });
  };
}
