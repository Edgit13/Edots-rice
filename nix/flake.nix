{
  description = "Edots — MangoWM + Quickshell rice (Nix adaptation)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Офіційний flake MangoWM (nixosModules.mango + HM wayland.windowManager.mango)
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Опційно: свіжіший Quickshell з upstream git (в nixpkgs-unstable він теж є: pkgs.quickshell)
    # quickshell = { url = "git+https://git.outfoxxed.me/outfoxxed/quickshell"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, mango, ... }: {
    nixosModules.edots = import ./module.nix;
    homeManagerModules.edots = import ./home.nix;

    # Приклад підключення у вашому flake:
    #   imports = [
    #     inputs.edots.nixosModules.edots          # системна частина (пакети, шрифти, сервіси)
    #     inputs.mango.nixosModules.mango          # programs.mango.enable = true
    #   ];
    #   home-manager.users.<you>.imports = [ inputs.edots.homeManagerModules.edots ];
  };
}
