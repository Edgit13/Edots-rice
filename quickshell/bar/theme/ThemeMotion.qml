pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeMotion — M3 Expressive motion: spatial (з overshoot) та effects (без), ролі руху.
// Поважає: Animations on/off, Expressive Motion, Animation Speed, Reduce Motion.
//   Behavior on width { MotionAnimation { role: "morph" } }
//   Behavior on color { MotionColorAnimation { role: "hover" } }
Singleton {
    id: root

    readonly property bool enabled: ThemeSettings.animations
    readonly property bool reduced: ThemeSettings.reduceMotion
    readonly property bool expressive: ThemeSettings.expressiveMotion && !reduced
    readonly property real speed: ThemeSettings.animationSpeed

    // cubic-bezier: [x1, y1, x2, y2, 1, 1]
    function curve(name) {
        switch (name) {
        // M3 standard / emphasized
        case "standard":             return [0.2, 0, 0, 1, 1, 1]
        case "standardDecelerate":   return [0, 0, 0, 1, 1, 1]
        case "standardAccelerate":   return [0.3, 0, 1, 1, 1, 1]
        case "emphasizedDecelerate": return [0.05, 0.7, 0.1, 1, 1, 1]
        case "emphasizedAccelerate": return [0.3, 0, 0.8, 0.15, 1, 1]
        // M3 Expressive spatial (overshoot) — fallback на standard без Expressive Motion
        case "spatialFast":    return expressive ? [0.42, 1.67, 0.21, 0.90, 1, 1] : [0.2, 0, 0, 1, 1, 1]
        case "spatialDefault": return expressive ? [0.38, 1.21, 0.22, 1.00, 1, 1] : [0.2, 0, 0, 1, 1, 1]
        case "spatialSlow":    return expressive ? [0.39, 1.29, 0.35, 0.98, 1, 1] : [0.2, 0, 0, 1, 1, 1]
        // M3 Expressive effects (без overshoot: колір/opacity)
        case "effectsFast":    return [0.31, 0.94, 0.34, 1, 1, 1]
        case "effectsDefault": return [0.34, 0.80, 0.34, 1, 1, 1]
        case "effectsSlow":    return [0.34, 0.88, 0.34, 1, 1, 1]
        default:               return [0.2, 0, 0, 1, 1, 1]
        }
    }

    // ролі: ms — базова тривалість, spatial — чи це рух/форма (reduce motion → миттєво)
    readonly property var _roles: ({
        enter:       { ms: 400, spatial: false, curve: "emphasizedDecelerate" },
        exit:        { ms: 200, spatial: false, curve: "emphasizedAccelerate" },
        expand:      { ms: 500, spatial: true,  curve: "spatialDefault" },
        collapse:    { ms: 350, spatial: true,  curve: "standard" },
        morph:       { ms: 500, spatial: true,  curve: "spatialDefault" },
        move:        { ms: 350, spatial: true,  curve: "spatialFast" },
        press:       { ms: 100, spatial: false, curve: "standard" },
        hover:       { ms: 150, spatial: false, curve: "effectsFast" },
        stateChange: { ms: 200, spatial: false, curve: "effectsDefault" },
        fade:        { ms: 300, spatial: false, curve: "effectsSlow" }
    })

    function scaled(ms, spatial) {
        if (!enabled) return 0
        if (reduced) return spatial ? 0 : Math.min(ms, 100)
        return Math.round(ms / speed)
    }
    function _role(role) { return _roles[role] || _roles.stateChange }
    function duration(role) { const r = _role(role); return scaled(r.ms, r.spatial) }
    function curveFor(role) { return curve(_role(role).curve) }
}
