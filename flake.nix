{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    poetry2nix.url = "github:nix-community/poetry2nix";
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
      nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        buildInputs = let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [poetry2nix.overlay];
          };
        in let
          env = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
          };
        in [alejandra.defaultPackage.aarch64-darwin env];

        shellHook = ''
          export PYTORCH_ENABLE_MPS_FALLBACK=1;
        '';
      };
  };
}
