import "root:/theme"
import "root:/services"
import QtQuick
import QtQuick.Layouts

// WorkspacesTab — огляд тегів/клієнтів по всіх моніторах (MangoService).
Item {
    id: root

    readonly property var monitorNames: Object.keys(MangoService.monitors)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.lg
        spacing: Theme.space.lg

        DashCard {
            visible: MangoService.focusedClient && MangoService.focusedClient.id !== null
            Layout.fillWidth: true
            title: "Активне вікно"

            RowLayout {
                width: parent.width
                spacing: Theme.space.sm
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    ThemedText { text: MangoService.focusedClient.title || "—"; style: Theme.type.bodyLarge
                                 elide: Text.ElideRight; Layout.fillWidth: true }
                    ThemedText { text: MangoService.focusedClient.appid || ""; style: Theme.type.labelSmall
                                 color: Theme.color.fgSurfaceVariant }
                }
                Text { text: "\ue5d0"; font { family: Theme.type.icons; pixelSize: Theme.type.iconS } color: Theme.color.fgSurfaceVariant
                       MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                   onClicked: MangoService.toggleFloatingFocusedClient() } }
                Text { text: "\ue5cd"; font { family: Theme.type.icons; pixelSize: Theme.type.iconS } color: Theme.color.error
                       MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                   onClicked: MangoService.closeFocusedClient() } }
            }
        }

        Repeater {
            model: root.monitorNames
            DashCard {
                id: monCard
                required property string modelData
                Layout.fillWidth: true
                title: modelData

                RowLayout {
                    width: parent.width
                    spacing: Theme.space.xs
                    Repeater {
                        model: MangoService.tagCount(modelData)
                        Rectangle {
                            required property int index
                            readonly property var t: MangoService.tag(modelData, index + 1)
                            Layout.preferredWidth: t.active ? 36 : 28
                            Layout.preferredHeight: 28
                            radius: Theme.shape.radius("md", height)
                            color: t.urgent ? Theme.color.errorContainer
                                 : t.active ? Theme.color.primary
                                 : t.occupied ? Theme.color.secondaryContainer
                                 : Theme.color.surfaceContainerHighest
                            Behavior on Layout.preferredWidth { MotionAnimation { role: "morph" } }

                            ThemedText {
                                anchors.centerIn: parent
                                text: parent.index + 1
                                style: Theme.type.labelSmall
                                color: parent.t.active ? Theme.color.fgPrimary
                                     : parent.t.urgent ? Theme.color.fgErrorContainer
                                     : parent.t.occupied ? Theme.color.fgSecondaryContainer
                                     : Theme.color.fgSurfaceVariant
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: MangoService.switchTag(monCard.modelData, parent.index + 1) }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
