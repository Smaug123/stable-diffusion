{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    poetry2nix.url = "github:Smaug123/poetry2nix/1cc79ef85789b7779f89d62209bba0cd4291dd60";
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
    in let
      python = nixpkgs.legacyPackages.aarch64-darwin.python39.override {enableNoSemanticInterposition = true;};
    in let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [poetry2nix.overlay];
      };
    in let
      env = pkgs.poetry2nix.mkPoetryEnv {
        projectDir = ./.;
        python = python;
        overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
          tokenizers = super.tokenizers.overridePythonAttrs {
            preBuild = ''export RUSTFLAGS="-L ${pkgs.libiconv}/lib -L ${pkgs.libcxxabi}/lib -L ${pkgs.libcxx}/lib -L framework=${pkgs.darwin.apple_sdk.frameworks.Security}/Library/Frameworks"'';
            nativeBuildInputs = (self.nativeBuildInputs or []) ++ [self.setuptools-rust pkgs.libiconv pkgs.darwin.apple_sdk.frameworks.Security] ++ (with pkgs.rustPlatform; [rust.cargo rust.rustc]);
          };
          ninja = super.ninja.overridePythonAttrs {
            nativeBuildInputs = (self.nativeBuildInputs or []) ++ [pkgs.cmake];
            preBuild = ''cd ..'';
          };
          meson-python = super.meson-python.overridePythonAttrs {
            nativeBuildInputs = (self.nativeBuildInputs or []) ++ [self.meson pkgs.ninja];
          };
          scipy = super.scipy.overridePythonAttrs {
            nativeBuildInputs = (self.nativeBuildInputs or []) ++ [pkgs.ninja] ++ [self.meson-python self.meson pkgs.gfortran pkgs.pkgconfig self.pythran self.python.pythonForBuild.pkgs.cython];
            preConfigure = ''${pkgs.gnused}/bin/sed -i "s!py3 = py_mod.find_installation()!py3 = py_mod.find_installation('${self.python}/bin/python')!g" meson.build'';
          };
          matplotlib = super.matplotlib.override {
            hardeningDisable = ["strictoverflow"];
          };
          torch-fidelity = super.torch-fidelity.overridePythonAttrs {
            preConfigure = ''
              ${pkgs.gnused}/bin/sed -i "s!with open('requirements.txt') as f:!requirements = ['numpy', 'Pillow', 'scipy', 'torch', 'torchvision', 'tqdm']!g" setup.py
              ${pkgs.gnused}/bin/sed -i "s!    requirements = f.read().splitlines()!!g" setup.py
            '';
          };
          opencv-python-headless = self.opencv-python;
          k-diffusion = super.k-diffusion.overridePythonAttrs {
            preConfigure = ''
              ${pkgs.gnused}/bin/sed -i "s!    CLIP @ git+https://github.com/openai/CLIP!    clip!g" setup.cfg
              ${pkgs.gnused}/bin/sed -i "s!    kornia!!g" setup.cfg
            '';
            buildInputs = (self.buildInputs or []) ++ [self.clip];
          };
        });
      };
    in
      nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        buildInputs = [alejandra.defaultPackage.aarch64-darwin];

        shellHook = ''
          export PYTORCH_ENABLE_MPS_FALLBACK=1;
          export PATH="${env}/bin:$PATH"
        '';
      };
  };
}
