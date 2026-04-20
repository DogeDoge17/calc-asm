{
  description = "super duper tiny calculator";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    packages.${system}.default = pkgs.stdenvNoCC.mkDerivation {
      pname = "calc";
      version = "0.1.0";

      src = ./.;
      dontConfigure = true;
      dontStrip = true;
      dontUnpack = true;

      nativeBuildInputs = [
        pkgs.nasm
        pkgs.binutils
      ];

      buildPhase = ''
        runHook preBuild
        nasm -f elf64 ${./main.asm} -o calc.o -gdwarf
        ld -T ${./tiny.ld} -s --build-id=none -o calc calc.o
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp calc $out/bin/calc
        runHook postInstall
      '';
    };

    apps.${system}.default = {
      type = "app";
      program = "${self.packages.${system}.default}/bin/calc";
    };
  };
}
