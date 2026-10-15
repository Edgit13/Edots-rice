pragma ComponentBehavior: Bound
import "root:/theme"
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
    spacing: Theme.space.xs
    visible: SettingsSearch.matches(Lang.searchText(r.cat, r.key, r.field))

    readonly property real value: Number(Settings.get(r.cat, r.key) ?? r.field.default)
    readonly property real lo: r.field.min !== undefined ? r.field.min : 0
    readonly property real hi: r.field.max !== undefined ? r.field.max : 100
    readonly property real fraction: (value - lo) / Math.max(0.0001, hi - lo)
    readonly property int decimals: (r.field.step !== undefined && r.field.step < 1) ? 2 : 0
    readonly property string suffix: Lang.unit(r.field.suffix || "")

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        ThemedText {
            Layout.fillWidth: true
            text: Lang.label(r.cat, r.key, r.field)
            style: Theme.type.bodyLarge
        }
        // значення — chip
        Rectangle {
            implicitWidth: valTxt.implicitWidth + Theme.space.lg
            implicitHeight: Theme.components.chipHeight - Theme.space.xs
            radius: Theme.shape.chip
            color: Theme.color.surfaceContainerHighest
            ThemedText {
                id: valTxt
                anchors.centerIn: parent
                text: r.value.toFixed(r.decimals) + r.suffix
                style: Theme.type.monoSmall
                color: Theme.color.fgSurfaceVariant
            }
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

    ThemedText {
        visible: Lang.desc(r.cat, r.key, r.field).length > 0
        Layout.fillWidth: true
        text: Lang.desc(r.cat, r.key, r.field)
        style: Theme.type.bodySmall
        color: Theme.color.fgSurfaceVariant
        wrapMode: Text.Wrap
    }
}
