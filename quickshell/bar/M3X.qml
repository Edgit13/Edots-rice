pragma Singleton
import "root:/"
import Quickshell
import QtQuick

// M3X.qml — Material 3 EXPRESSIVE extension (поверх Md, не замінює).
// ① пружини з overshoot  ② бібліотека M3E-форм (7 фігур)  ③ виразні кольори.
Singleton {
    id: x

    // ---------- пружини (spatial spring, damping ~0.85) ----------
    function springOut(t) {
        // damped harmonic: легкий overshoot у кінці
        if (t <= 0) return 0
        if (t >= 1) return 1
        return 1 - Math.exp(-5.2 * t) * Math.cos(9.0 * t)
    }
    function springInOut(t) {
        if (t < 0.5) return 0.5 * springOut(t * 2)
        return 0.5 + 0.5 * (1 - springOut((1 - t) * 2))
    }

    // ---------- бібліотека форм (M3E morph set) ----------
    function lobed(n, amp, kPeak, kValley) {
        return function(th) {
            const c = Math.cos(n * th)
            const v = c >= 0 ? Math.pow(c, kPeak) : -Math.pow(-c, kValley)
            return 1 + amp * v
        }
    }
    function roundedPolygon(n, roundness) {
        const s = (2 * Math.PI) / n
        return function(th) {
            const local = (((th % s) + s) % s) - s / 2
            const poly = Math.cos(Math.PI / n) / Math.cos(local)
            return poly * (1 - roundness) + roundness
        }
    }
    function stadiumF(a, b) {
        const h = a - b
        return function(th) {
            const dx = Math.cos(th), dy = Math.sin(th)
            const ay = Math.abs(dy)
            if (ay > 1e-6) {
                const r = b / ay
                if (Math.abs(r * dx) <= h) return r
            }
            const cx = h * (dx >= 0 ? 1 : -1)
            const cd = cx * dx
            return cd + Math.sqrt(Math.max(0, cd * cd - (h * h - b * b)))
        }
    }
    function ellipseF(a, b) {
        return function(th) {
            const c = Math.cos(th), s = Math.sin(th)
            return (a * b) / Math.sqrt(b * b * c * c + a * a * s * s)
        }
    }

    // ті самі 7 форм, що в LoadingIndicator
    function shapeFns() {
        return [
            lobed(10, 0.11, 1.0, 1.0),
            lobed(9, 0.075, 0.8, 1.5),
            roundedPolygon(5, 0.45),
            stadiumF(1.0, 0.56),
            lobed(8, 0.16, 1.7, 0.8),
            lobed(4, 0.17, 0.7, 1.4),
            ellipseF(1.0, 0.74)
        ]
    }

    // ---------- виразні кольори (M3E: соковиті tertiary/secondary) ----------
    readonly property color accentVivid: Md.primary
    readonly property color tertiaryVivid: Md.tertiary
    readonly property color tertiaryContainer: Md.tertiaryContainer
    readonly property color onTertiaryContainer: Md.onSurface

    // тривалості (M3E трохи повільніші, "важчі")
    readonly property int durExpressive: 500
}
