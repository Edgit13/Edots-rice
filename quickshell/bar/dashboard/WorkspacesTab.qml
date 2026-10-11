import "root:/theme"
import "root:/services"
import QtQuick
import QtQuick.Layouts

// WorkspacesTab — огляд тегів/клієнтів по всіх моніторах.
Item {
    id: root

    readonly property var monitorNames: Object.keys(MangoService.monitors)

    component IconButton: Rectangle {
        id: btn
        property string icon: ""
        property color tint: Theme.color.fgSurfaceVariant
        signal clicked()

        implicitWidth: 32
        implicitHeight: 32
        radius: 16

        color: bma.pressed
             ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
             : bma.containsMouse
                 ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
                 : "transparent"
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            color: btn.tint
        }

        MouseArea {
            id: bma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

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
                    ThemedText {
                        text: MangoService.focusedClient.title || "—"
                        style: Theme.type.bodyLarge
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    ThemedText {
                        text: MangoService.focusedClient.appid || ""
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                    }
                }
                IconButton {
                    icon: "\ue5d0"
                    onClicked: MangoService.toggleFloatingFocusedClient()
                }
                IconButton {
                    icon: "\ue5cd"
                    tint: Theme.color.error
                    onClicked: MangoService.closeFocusedClient()
                }
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
                            id: tagRect
                            required property int index
                            readonly property var t: MangoService.tag(modelData, index + 1)
                            Layout.preferredWidth: t.active ? 36 : 28
                            Layout.preferredHeight: 28
                            radius: Theme.shape.radius("md", height)

                            color: t.urgent ? Theme.color.errorContainer
                                 : t.active ? Theme.color.primary
                                 : t.occupied ? Theme.color.secondaryContainer
                                 : tma.pressed
                                     ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
                                     : tma.containsMouse
                                         ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
                                         : Theme.color.surfaceContainerHighest
                            Behavior on color { MotionColorAnimation { role: "hover" } }

                            ThemedText {
                                anchors.centerIn: parent
                                text: tagRect.index + 1
                                style: Theme.type.labelSmall
                                color: tagRect.t.active ? Theme.color.fgPrimary
                                     : tagRect.t.urgent ? Theme.color.fgErrorContainer
                                     : tagRect.t.occupied ? Theme.color.fgSecondaryContainer
                                     : Theme.color.fgSurfaceVariant
                            }

                            MouseArea {
                                id: tma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MangoService.switchTag(monCard.modelData, tagRect.index + 1)
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
