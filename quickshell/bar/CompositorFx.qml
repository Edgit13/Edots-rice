pragma Singleton
import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick

// ==========================================================================
// CompositorFx.qml — застосування blur-налаштувань до MangoWM.
// Config (blur.enabled / blur.strength) -> ~/.config/mango/config.conf
// (blur_layer, blur_params_radius) -> mmsg reload_config. Hot-reload, без
// перелогіну. Singleton інстанціюється з PillShell (compositorFxRef).
// ==========================================================================

Singleton {
    id: fxRoot

    readonly property bool blurEnabled: Config.get("blur", "enabled")
    readonly property int blurStrength: Config.get("blur", "strength")

    Process { id: applyProc }

    function applyFx() {
        if (!Config.loaded)
            return
        applyProc.command = ["sh", "-c", '
f="$HOME/.config/mango/config.conf"
touch "$f"
sed -i "/^blur_layer=/d;/^blur_params_radius=/d;/^blur_params_num_passes=/d" "$f"
printf "blur_layer=%s\nblur_params_radius=%s\nblur_params_num_passes=2\n" "$1" "$2" >> "$f"
mmsg reload_config 2>/dev/null || true
', "sh", fxRoot.blurEnabled ? "1" : "0", String(fxRoot.blurStrength)]
        applyProc.running = true
    }

    onBlurEnabledChanged: applyFx()
    onBlurStrengthChanged: applyFx()
}
