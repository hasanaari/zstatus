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

    perSystem = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};

      runtimeDeps = with pkgs; [
        bash
        coreutils
        gawk
        procps
        wireplumber
      ];

      package = pkgs.stdenv.mkDerivation {
        pname = "zstatus";
        version = "0.0.0";
        src = ./.;

        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.pkg-config
          pkgs.zig
        ];
        buildInputs = [pkgs.libX11 pkgs.stdenv.cc.libc];

        X11_INCLUDE_PATHS = pkgs.lib.makeSearchPath "include" [
          (pkgs.lib.getDev pkgs.libX11)
          (pkgs.lib.getDev pkgs.xorgproto)
        ];

        dontConfigure = true;
        dontPatchELF = true;

        buildPhase = ''
          runHook preBuild
          export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
          zig build --system "$PWD/zig-pkg" \
            -Dtarget=${pkgs.stdenv.hostPlatform.parsed.cpu.name}-linux-gnu \
            -Ddynamic-linker=${pkgs.stdenv.cc.bintools.dynamicLinker} \
            -Druntime-library-paths=${pkgs.lib.makeLibraryPath [pkgs.libX11 pkgs.stdenv.cc.libc]} \
            -Doptimize=ReleaseFast --prefix "$out"
          runHook postBuild
        '';

        dontInstall = true;

        meta = {
          mainProgram = "zstatus";
          platforms = pkgs.lib.platforms.linux;
        };

        postFixup = ''
          wrapProgram "$out/bin/zstatus" \
            --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
        '';
      };
    in {
      packages.default = package;

      devShells.default = pkgs.mkShell {
        inputsFrom = [package];
        packages = [pkgs.zls] ++ runtimeDeps;
        inherit (package) X11_INCLUDE_PATHS;
      };
    });
  in {
    packages = forAllSystems (system: perSystem.${system}.packages);
    devShells = forAllSystems (system: perSystem.${system}.devShells);
  };
}
