{
  description = "Edots — MangoWM + Quickshell rice (Nix adaptation)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, mango, ... }:
  let
    lib = nixpkgs.lib;
  in {
    nixosModules.edots = import ./module.nix;
    homeManagerModules.edots = import ./home.nix;

    # ── Авто-конфігурація для install.sh: імпортує існуючий /etc/nixos ──
    # local-user.nix генерує install.sh (не комітити) — підключення HM для юзера.
    nixosConfigurations.edots = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./host.nix
        home-manager.nixosModules.home-manager
        mango.nixosModules.mango
        ./module.nix
        ({ ... }: {
          edots.enable = true;
          programs.mango.enable = true;
          services.displayManager.defaultSession = "mango";
          home-manager.useUserPackages = true;
          home-manager.useGlobalPkgs = true;
        })
      ] ++ lib.optional (builtins.pathExists ./local-user.nix) ./local-user.nix;
    };
  };
}
