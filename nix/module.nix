# module.nix — NixOS-частина Edots (NixOS 26.05-ready): rice + hardware-фічі.
{ config, lib, pkgs, ... }:

let
  rice = import ./rice.nix { inherit pkgs; };
  cfg = config.edots;
in
{
  options.edots = {
    enable = lib.mkEnableOption "Edots rice (MangoWM + Quickshell)";
    bluetooth.enable = lib.mkOption {
      type = lib.types.bool; default = true;
      description = "Bluetooth (hardware.bluetooth).";
    };
    virtualization.enable = lib.mkOption {
      type = lib.types.bool; default = true;
      description = "Libvirt/QEMU/KVM + virt-manager (хост для віртуалок).";
    };
    vmGuest = lib.mkOption {
      type = lib.types.enum [ "none" "virtualbox" "vmware" ];
      default = "none";
      description = "Guest additions, якщо NixOS ставиться ВСЕРЕДИНУ ВМ.";
    };
    steam.enable = lib.mkOption {
      type = lib.types.bool; default = true;
    };
    printing.enable = lib.mkOption {
      type = lib.types.bool; default = true;
    };
    flatpak.enable = lib.mkOption {
      type = lib.types.bool; default = true;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # ── Ядро rice ──
    {
      environment.systemPackages =
        rice.mango ++ rice.shell ++ rice.capture ++ rice.barDeps ++ rice.cli ++ rice.terms;

      fonts.packages = rice.fonts;

      networking.networkmanager.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
      security.rtkit.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      # Display manager: mkDefault — якщо у вашій configuration.nix вже є DM,
      # він переможе; інакше sddm(wayland) + сесія mango за замовчуванням.
      services.displayManager.sddm.enable = lib.mkDefault true;
      services.displayManager.sddm.wayland.enable = lib.mkDefault true;
      services.displayManager.defaultSession = lib.mkDefault "mango";

      # Бар: systemd user-сервіс із явним -p (фікс «дефолтний конф після сліпу»).
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
    }

    # ── Фічі (кожна вимкнена — просто не оголошується) ──
    (lib.mkIf cfg.bluetooth.enable {
      hardware.bluetooth.enable = true;
    })

    (lib.mkIf cfg.virtualization.enable {
      virtualisation.libvirtd.enable = true;
      virtualisation.spiceUSBRedirection.enable = true;
      environment.systemPackages = [ pkgs.virt-manager pkgs.qemu_kvm ];
    })

    (lib.mkIf (cfg.vmGuest == "virtualbox") {
      virtualisation.virtualbox.guest.enable = true;
    })
    (lib.mkIf (cfg.vmGuest == "vmware") {
      virtualisation.vmware.guest.enable = true;
    })

    (lib.mkIf cfg.steam.enable {
      programs.steam.enable = true;
    })

    (lib.mkIf cfg.printing.enable {
      services.printing.enable = true;
    })

    (lib.mkIf cfg.flatpak.enable {
      services.flatpak.enable = true;
    })
  ]);
}
