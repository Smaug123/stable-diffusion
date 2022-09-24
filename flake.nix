{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    poetry2nix.url = "github:Smaug123/poetry2nix/694a82f3562bdde4108badefc3a058c7743cae36";
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
	      onnx = pkgs.python3Packages.onnx;
	      scipy = pkgs.python3Packages.scipy;
	      matplotlib = pkgs.python3Packages.matplotlib;
  });
          };
        in [alejandra.defaultPackage.aarch64-darwin "${env}/bin/python"];

        shellHook = ''
          export PYTORCH_ENABLE_MPS_FALLBACK=1;
        '';
      };
  };
}
