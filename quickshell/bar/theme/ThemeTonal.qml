pragma Singleton
import QtQuick
import Quickshell

// ThemeTonal — генерація M3 tonal-палітр (Lab-LCH ≈ HCT: tone = CIE L*).
// Використовується, коли немає готових matugen-ролей (Light theme, custom accent).
Singleton {
    id: root

    // ---------- color math ----------
    function _lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
    function _gam(c) { return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055 }
    function _f(t)   { return t > 216 / 24389 ? Math.pow(t, 1 / 3) : (24389 / 27 * t + 16) / 116 }
    function _finv(t) { const t3 = t * t * t; return t3 > 216 / 24389 ? t3 : (116 * t - 16) / (24389 / 27) }
    function _clamp01(v) { return Math.max(0, Math.min(1, v)) }

    function parseHex(hex) {
        let h = String(hex).replace("#", "")
        if (h.length === 3)
            h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2)
        if (h.length === 8) h = h.slice(2)
        if (h.length !== 6) return null
        const n = parseInt(h, 16)
        if (isNaN(n)) return null
        return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255]
    }

    function toHex(rgb) {
        let s = "#"
        for (let i = 0; i < 3; i++) {
            const v = Math.max(0, Math.min(255, Math.round(rgb[i] * 255)))
            s += (v < 16 ? "0" : "") + v.toString(16)
        }
        return s
    }

    function hexToLch(hex) {
        const c = parseHex(hex)
        if (!c) return { l: 50, c: 36, h: 280 }
        const r = _lin(c[0]), g = _lin(c[1]), b = _lin(c[2])
        const X = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
        const Y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
        const Z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
        const fx = _f(X), fy = _f(Y), fz = _f(Z)
        const a = 500 * (fx - fy), bb = 200 * (fy - fz)
        let h = Math.atan2(bb, a) * 180 / Math.PI
        if (h < 0) h += 360
        return { l: 116 * fy - 16, c: Math.sqrt(a * a + bb * bb), h: h }
    }

    function _lchToLinear(L, C, h) {
        const hr = h * Math.PI / 180
        const a = C * Math.cos(hr), b = C * Math.sin(hr)
        const fy = (L + 16) / 116, fx = fy + a / 500, fz = fy - b / 200
        const X = _finv(fx) * 0.95047, Y = _finv(fy), Z = _finv(fz) * 1.08883
        return [ 3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z,
                -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z,
                 0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z ]
    }
    function _inGamut(v) {
        const e = 0.0005
        return v[0] >= -e && v[0] <= 1 + e && v[1] >= -e && v[1] <= 1 + e && v[2] >= -e && v[2] <= 1 + e
    }

    // tone t (0..100 = L*), hue (deg), chroma (gamut-clipped by chroma reduction)
    function tone(hue, chroma, t) {
        if (t <= 0) return "#000000"
        if (t >= 100) return "#ffffff"
        let lin = _lchToLinear(t, chroma, hue)
        if (!_inGamut(lin)) {
            let lo = 0, hi = chroma
            for (let i = 0; i < 20; i++) {
                const mid = (lo + hi) / 2
                if (_inGamut(_lchToLinear(t, mid, hue))) lo = mid; else hi = mid
            }
            lin = _lchToLinear(t, lo, hue)
        }
        return toHex([_gam(_clamp01(lin[0])), _gam(_clamp01(lin[1])), _gam(_clamp01(lin[2]))])
    }

    // ---------- contrast (WCAG) ----------
    function luminance(c) { return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b) }
    function contrast(a, b) {
        const la = luminance(a), lb = luminance(b)
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
    }

    function snakeToCamel(s) {
        return String(s).replace(/_([a-z])/g, function (m, ch) { return ch.toUpperCase() })
    }

    // ---------- scheme ----------
    // Повертає { roleName: "#rrggbb" } для M3 ролей + success/warning.
    function makeScheme(seedHex, dark) {
        const s = hexToLch(seedHex)
        const h = s.h
        const pc = Math.max(32, Math.min(s.c, 60))
        const sc = Math.max(12, Math.min(pc * 0.4, 24))
        const tc = Math.max(24, pc * 0.7)

        const P  = function (t) { return tone(h, pc, t) }
        const S  = function (t) { return tone(h, sc, t) }
        const T  = function (t) { return tone(h + 60, tc, t) }
        const N  = function (t) { return tone(h, 4, t) }
        const NV = function (t) { return tone(h, 8, t) }
        const E  = function (t) { return tone(32, 84, t) }
        const G  = function (t) { return tone(145, 40, t) }   // success
        const W  = function (t) { return tone(85, 56, t) }    // warning

        if (dark) return {
            primary: P(80), onPrimary: P(20), primaryContainer: P(30), onPrimaryContainer: P(90),
            secondary: S(80), onSecondary: S(20), secondaryContainer: S(30), onSecondaryContainer: S(90),
            tertiary: T(80), onTertiary: T(20), tertiaryContainer: T(30), onTertiaryContainer: T(90),
            error: E(80), onError: E(20), errorContainer: E(30), onErrorContainer: E(90),
            success: G(80), onSuccess: G(20), successContainer: G(30), onSuccessContainer: G(90),
            warning: W(80), onWarning: W(20), warningContainer: W(30), onWarningContainer: W(90),
            background: N(6), onBackground: N(90), surface: N(6), onSurface: N(90),
            surfaceVariant: NV(30), onSurfaceVariant: NV(80),
            surfaceDim: N(6), surfaceBright: N(24),
            surfaceContainerLowest: N(4), surfaceContainerLow: N(10), surfaceContainer: N(12),
            surfaceContainerHigh: N(17), surfaceContainerHighest: N(22),
            outline: NV(60), outlineVariant: NV(30),
            inverseSurface: N(90), inverseOnSurface: N(20), inversePrimary: P(40), surfaceTint: P(80),
            shadow: "#000000", scrim: "#000000"
        }
        return {
            primary: P(40), onPrimary: P(100), primaryContainer: P(90), onPrimaryContainer: P(10),
            secondary: S(40), onSecondary: S(100), secondaryContainer: S(90), onSecondaryContainer: S(10),
            tertiary: T(40), onTertiary: T(100), tertiaryContainer: T(90), onTertiaryContainer: T(10),
            error: E(40), onError: E(100), errorContainer: E(90), onErrorContainer: E(10),
            success: G(40), onSuccess: G(100), successContainer: G(90), onSuccessContainer: G(10),
            warning: W(40), onWarning: W(100), warningContainer: W(90), onWarningContainer: W(10),
            background: N(98), onBackground: N(10), surface: N(98), onSurface: N(10),
            surfaceVariant: NV(90), onSurfaceVariant: NV(30),
            surfaceDim: N(87), surfaceBright: N(98),
            surfaceContainerLowest: N(100), surfaceContainerLow: N(96), surfaceContainer: N(94),
            surfaceContainerHigh: N(92), surfaceContainerHighest: N(90),
            outline: NV(50), outlineVariant: NV(80),
            inverseSurface: N(20), inverseOnSurface: N(95), inversePrimary: P(80), surfaceTint: P(40),
            shadow: "#000000", scrim: "#000000"
        }
    }
}
