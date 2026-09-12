pragma Singleton
import "root:/"
import Quickshell
import QtQuick

// ==========================================================================
// Anim.qml — глобальний регулятор анімацій (Phase "animations everywhere").
//
// Anim.ms(base) — єдина точка входу для тривалостей у барі та Settings:
//   - animations.enabled == false  -> 0 (миттєво, Behaviors просто не тягнуться)
//   - animations.globalSpeed       -> дільник (2.0 = вдвічі швидше)
// Використання: NumberAnimation { duration: Anim.ms(150) }
// ==========================================================================

Singleton {
    id: animRoot

    function ms(base) {
        if (!Config.get("animations", "enabled"))
            return 0
        const speed = Config.get("animations", "globalSpeed")
        const s = (typeof speed === "number" && speed > 0) ? speed : 1.0
        return Math.max(0, Math.round(base / s))
    }
}
