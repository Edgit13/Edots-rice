# module.nix — NixOS-частина Edots: пакети, шрифти, системні сервіси rice.
{ config, lib, pkgs, ... }:

let
  rice = import ./rice.nix { inherit pkgs; };
in
{
  options.edots.enable = lib.mkEnableOption "Edots rice (MangoWM + Quickshell)";

  config = lib.mkIf config.edots.enable {
    environment.systemPackages =
      rice.mango ++ rice.shell ++ rice.capture ++ rice.barDeps ++ rice.cli ++ rice.terms;

    fonts.packages = rice.fonts;

    # --- Аудіо / мережа / bluetooth (як у поточній системі) ---
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    services.bluetooth.enable = true;
    networking.networkmanager.enable = true;

    # --- MangoWM як сесія ---
    # Варіант A (flake input mango): programs.mango.enable = true;
    #   + services.displayManager.defaultSession = "mango";
    # Варіант B (без flake): nixpkgs pkgs.mangowc + власна .desktop-сесія (див. README).

    # Портали/змінні Wayland
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
