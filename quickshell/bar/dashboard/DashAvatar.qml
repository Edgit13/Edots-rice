import "root:/theme"
import Quickshell
import QtQuick
import QtQuick.Effects

// DashAvatar — читає ~/.face; якщо файлу нема/битий — generic-іконка людини.
Item {
    id: root
    property int size: 56

    implicitWidth: size
    implicitHeight: size

    readonly property string facePath: Quickshell.env("HOME") + "/.face"
    readonly property bool loaded: img.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        radius: size / 2
        color: Theme.settings.nothing ? "transparent" : Theme.color.secondaryContainer
        border.width: Theme.settings.nothing ? 1 : 0
        border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.28)
        visible: !root.loaded

        Text {
            anchors.centerIn: parent
            text: "\ue7fd"
            font { family: Theme.type.icons; pixelSize: root.size * 0.55 }
            color: Theme.color.fgSecondaryContainer
        }
    }

    Image {
        id: img
        anchors.fill: parent
        source: "file://" + root.facePath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle {
        id: maskShape
        anchors.fill: parent
        radius: size / 2
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.loaded
        maskEnabled: true
        maskSource: maskShape
    }
}
