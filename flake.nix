{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    poetry2nix.url = "github:Smaug123/poetry2nix/90b74cb594aafa259fb715a59bf27d35a354d82f";
    alejandra = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:kamadorueda/alejandra/3.0.0";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    poetry2nix,
    alejandra,
    ...
  }: {
    devShell.aarch64-darwin = let
      system = "aarch64-darwin";
    in
    let python = nixpkgs.legacyPackages.aarch64-darwin.python39.override { enableNoSemanticInterposition = true;
    }; in 
      nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        buildInputs = let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [poetry2nix.overlay];
          };
        in let
          env = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            python = python;
            overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
              tokenizers = super.tokenizers.override {
                  preBuild = ''export RUSTFLAGS="-L ${pkgs.libiconv}/lib -L ${pkgs.libcxxabi}/lib -L ${pkgs.libcxx}/lib -L framework=${pkgs.darwin.apple_sdk.frameworks.Security}/Library/Frameworks"'';
                  nativeBuildInputs = (self.nativeBuildInputs or []) ++ [ self.setuptools-rust pkgs.libiconv pkgs.darwin.apple_sdk.frameworks.Security ] ++ (with pkgs.rustPlatform; [ rust.cargo rust.rustc ]);
              };
	      # onnx = pkgs.python3Packages.onnx;
	        scipy = super.scipy.override { preBuild = ''pwd''; };
	        matplotlib = super.matplotlib.override {
                hardeningDisable = ["strictoverflow"];
            };
  });
          };
        in [alejandra.defaultPackage.aarch64-darwin "${env}/bin/python"];

        shellHook = ''
          export PYTORCH_ENABLE_MPS_FALLBACK=1;
        '';
      };
  };
}
