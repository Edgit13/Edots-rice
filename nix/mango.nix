# mango.nix — ПРИКЛАД: MangoWM через офіційний HM-модуль (attrset-конфіг).
# Edots використовує file-based конфіг (~/.config/mango/*.conf — вже в home.nix).
# Цей файл — ОПЦІЙНА міграція, якщо захочете повністю декларативний mango.
{ ... }:

{
  wayland.windowManager.mango = {
    enable = true;
    # autostart_sh — альтернатива autostart.conf:
    # autostart_sh = '''
    #   qs -p ~/.config/quickshell/bar/shell.qml &
    #   swaync &
    #   nm-applet &
    # ''';

    settings = {
      # Приклад з ваших conf (див. mango/config.conf, decorations.conf):
      blur = 1;
      blur_optimized = 1;
      blur_params = { radius = 7; num_passes = 2; };
      animations = 1;
      # bind = [ "SUPER,Space,exec,qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleLauncher" ];
      # Повний перенос binds.conf → settings.bind — вручну (формат mango: "mod,key,action,...").
    };
  };
}
