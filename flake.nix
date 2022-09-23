{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    poetry2nix.url = "github:Smaug123/poetry2nix/relative-absolute";
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
            #overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
    #torch = super.torch.override {
    #    preferWheel = true;
    #}; #"torch-1.13.0.dev20220904";
    #torchvision = "torchvision-0.12.0";
    #torchaudio = "torchaudio-0.13.0.dev20220904";
  #});
          };
        in [alejandra.defaultPackage.aarch64-darwin "${env}/bin/python"];

        shellHook = ''
          export PYTORCH_ENABLE_MPS_FALLBACK=1;
        '';
      };
  };
}
