# module.nix — NixOS-частина Edots: пакети, шрифти, сервіси rice.
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

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    services.bluetooth.enable = true;
    networking.networkmanager.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # ── Бар: systemd user-сервіс із ЯВНИМ шляхом до конфіга.
    # Фікс «після сліпу стартує дефолтний конф»: ніхто ніколи не запускає
    # голий `qs`; після resume/падіння — Restart повертає саме твій shell.qml.
    systemd.user.services.edots-bar = {
      description = "Edots Quickshell bar (explicit -p, survives resume)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.quickshell}/bin/qs -p %h/.config/quickshell/bar/shell.qml";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
