pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

// Секція-картка (рідко використовується напряму: SettingsApp малює connected-list сам).
Rectangle {
    id: c
    property string title: ""
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.space.lg * 2
    radius: Theme.shape.cardLarge
    color: Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainer
    border.width: Theme.settings.nothing ? 1 : 0
    border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.16)

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.space.lg
        }
        spacing: Theme.space.md

        ThemedText {
            visible: c.title.length > 0
            Layout.fillWidth: true
            text: c.title
            style: Theme.type.labelLarge
            color: Theme.color.fgSurfaceVariant
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: Theme.space.sm
        }
    }
}
