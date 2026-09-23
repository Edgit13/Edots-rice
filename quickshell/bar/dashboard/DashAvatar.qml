import "root:/theme"
import Quickshell
import QtQuick
import QtQuick.Effects

// DashAvatar — читає ~/.face; якщо файлу нема/битий — generic-іконка людини.
// Кругла маска через MultiEffect (Qt Quick 6 Effects), бо clip:true на Rectangle
// не обрізає дітей по заокругленню, лише по прямокутних межах.
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
        color: Theme.color.secondaryContainer
        visible: !root.loaded

        Text {
            anchors.centerIn: parent
            text: "\ue7fd"   // person
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
