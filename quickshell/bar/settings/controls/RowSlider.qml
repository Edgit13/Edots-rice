pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: r
    required property string category
    required property string configKey
    required property string label
    property string description: ""
    property string suffix: ""
    property int decimals: 2

    Layout.fillWidth: true
    spacing: M3.s4
    visible: SettingsSearch.matches(label)

    readonly property var s: SettingsState.schema[category] ? SettingsState.schema[category][configKey] : null
    readonly property real value: s ? Number(SettingsState.get(category, configKey) ?? s.default) : 0
    readonly property real fraction: s ? (value - s.min) / Math.max(0.0001, s.max - s.min) : 0

    RowLayout {
        Layout.fillWidth: true
        spacing: M3.s8
        Text {
            Layout.fillWidth: true
            text: r.label
            color: M3.m3OnSurface
            font: M3.bodyLarge
        }
        Text {
            text: r.value.toFixed(r.decimals) + r.suffix
            color: M3.m3OnSurfaceVariant
            font: M3.labelMedium
        }
        ResetDot { category: r.category; configKey: r.configKey }
    }

    MaterialSlider {
        Layout.fillWidth: true
        value: r.fraction
        showValue: true
        decimals: r.decimals
        suffix: r.suffix
        onMoved: (f) => {
            if (!r.s) return
            const raw = r.s.min + f * (r.s.max - r.s.min)
            const step = r.s.step || 0
            const snapped = step > 0 ? Math.round(raw / step) * step : raw
            SettingsState.set(r.category, r.configKey, snapped)
        }
    }

    Text {
        visible: r.description.length > 0
        Layout.fillWidth: true
        text: r.description
        color: M3.m3OnSurfaceVariant
        font: M3.bodySmall
        wrapMode: Text.Wrap
    }
}
