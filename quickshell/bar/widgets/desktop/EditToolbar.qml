import "root:/theme"
import "root:/settings"
import QtQuick

// EditToolbar — панель режиму редагування: підказка, пресети, скинути позиції, готово.
Rectangle {
    id: bar

    visible: WidgetsConfig.editing
    implicitWidth: col.implicitWidth + 40
    implicitHeight: col.implicitHeight + 32
    radius: Theme.shape.token("xl")
    color: ThemeColors.surfaceContainerHighest
    border.width: 1
    border.color: Theme.alpha(ThemeColors.fgSurface, 0.12)

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 12

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lang.t("ui.widgets.editHint")
            style: Theme.type.titleSmall
            color: ThemeColors.fgSurfaceVariant
        }
        Flow {
            width: 520
            spacing: 8
            Repeater {
                model: WidgetsConfig.presetIds
                WidgetChip {
                    required property string modelData
                    text: Lang.opt("widgets", "preset", modelData)
                    onClicked: WidgetsConfig.applyPreset(modelData)
                }
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            WidgetChip { text: Lang.t("ui.widgets.reset"); onClicked: WidgetsConfig.resetPlacement() }
            WidgetChip { text: Lang.t("ui.widgets.done"); primary: true; onClicked: WidgetsConfig.setEditing(false) }
        }
    }
}
