# home.nix — home-manager частина Edots: dotfiles з репозиторію + user-пакети.
#
# ВАЖЛИВО: runtime-файли (~/.config/quickshell/{colors.json,settings.json,
# tasks.json,active-preset,presets/}) НЕ лінкуємо — їх пише shell/matugen.
# Все інше — symlink на робочу копію репо: правки одразу живі.
{ config, lib, pkgs, ... }:

let
  rice = import ./rice.nix { inherit pkgs; };
  # Шлях до кореня репозиторію (цей файл лежить у <repo>/nix/)
  repo = ../.;
in
{
  options.edots.home.enable = lib.mkEnableOption "Edots home (dotfiles + user packages)";

  config = lib.mkIf config.edots.home.enable {
    home.packages = rice.shell ++ rice.capture ++ rice.cli;

    # --- Quickshell (бар + Settings/Dashboard/TaskManager) ---
    xdg.configFile."quickshell/bar".source = repo + "/quickshell/bar";
    xdg.configFile."quickshell/scripts".source = repo + "/quickshell/scripts";
    # colors.json / settings.json / tasks.json / presets/ — НЕ керуємо (runtime).

    # --- MangoWM (усі conf; blur-рядки дописує CompositorFx — див. README) ---
    xdg.configFile."mango".source = repo + "/mango";

    # --- Решта конфігів rice ---
    xdg.configFile."swaync".source = repo + "/swaync";
    xdg.configFile."rofi".source = repo + "/rofi";
    xdg.configFile."kitty".source = repo + "/kitty";
    xdg.configFile."alacritty".source = repo + "/alacritty";
    xdg.configFile."ghostty".source = repo + "/ghostty";
    xdg.configFile."fish".source = repo + "/fish";
    xdg.configFile."nvim".source = repo + "/nvim";
    xdg.configFile."fastfetch".source = repo + "/fastfetch";
    xdg.configFile."gtk-3.0".source = repo + "/gtk-3.0";
    xdg.configFile."gtk-4.0".source = repo + "/gtk-4.0";
    xdg.configFile."swaylock".source = repo + "/swaylock";
    xdg.configFile."firefox/chrome".source = repo + "/firefox/chrome";

    home.file.".config/kdeglobals".source = repo + "/kdeglobals";
    home.file.".config/dolphinrc".source = repo + "/dolphinrc";
    home.file."edots".source = repo + "/edots";   # CLI-утиліти (utimer/upkg/task-manager)

    # Сесійні змінні Wayland (еквівалент mango/env.conf)
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
