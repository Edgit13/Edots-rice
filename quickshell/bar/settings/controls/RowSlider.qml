pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: r
    required property string cat
    required property string key
    required property var field

    Layout.fillWidth: true
    spacing: M3.s4
    visible: SettingsSearch.matches(r.field.label || r.key)

    readonly property real value: Number(Settings.get(r.cat, r.key) ?? r.field.default)
    readonly property real lo: r.field.min !== undefined ? r.field.min : 0
    readonly property real hi: r.field.max !== undefined ? r.field.max : 100
    readonly property real fraction: (value - lo) / Math.max(0.0001, hi - lo)
    readonly property int decimals: (r.field.step !== undefined && r.field.step < 1) ? 2 : 0
    readonly property string suffix: r.field.suffix || ""

    RowLayout {
        Layout.fillWidth: true
        spacing: M3.s8
        Text {
            Layout.fillWidth: true
            text: r.field.label || r.key
            color: M3.m3OnSurface
            font: M3.bodyLarge
        }
        Text {
            text: r.value.toFixed(r.decimals) + r.suffix
            color: M3.m3OnSurfaceVariant
            font: M3.labelMedium
        }
        ResetDot { cat: r.cat; key: r.key }
    }

    MaterialSlider {
        Layout.fillWidth: true
        value: r.fraction
        showValue: true
        decimals: r.decimals
        suffix: r.suffix
        onMoved: (f) => {
            const raw = r.lo + f * (r.hi - r.lo)
            const step = r.field.step || 0
            const snapped = step > 0 ? Math.round(raw / step) * step : raw
            Settings.set(r.cat, r.key, snapped)
        }
    }

    Text {
        visible: !!r.field.desc
        Layout.fillWidth: true
        text: r.field.desc || ""
        color: M3.m3OnSurfaceVariant
        font: M3.bodySmall
        wrapMode: Text.Wrap
    }
}
