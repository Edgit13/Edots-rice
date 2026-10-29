import "root:/theme"
import "root:/services"
import "root:/settings"
import QtQuick

// MediaWidget — назва / виконавець, prev · play/pause · next, прогрес (MediaService).
WidgetFrame {
    id: root
    kind: "media"

    property real unit: 200

    Timer {
        interval: 1000
        repeat: true
        running: MediaService.playing && root.visible
        onTriggered: MediaService.poll()
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: root.unit * 0.03

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: MediaService.has ? (MediaService.title || Lang.t("ui.media.unknown")) : Lang.t("ui.media.none")
            style: Theme.type.titleMedium
            font.pixelSize: root.unit * 0.085
            emphasized: true
            color: root.onColor
        }
        ThemedText {
            width: parent.width
            visible: MediaService.has && MediaService.artist.length > 0
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: MediaService.artist
            style: Theme.type.bodyMedium
            font.pixelSize: root.unit * 0.065
            color: Theme.alpha(root.onColor, 0.7)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.unit * 0.04
            opacity: MediaService.has ? 1 : 0.4
            WidgetButton {
                size: root.unit * 0.17; glyph: "\ue045"
                anchors.verticalCenter: parent.verticalCenter
                onColor: root.onColor; fillColor: root.onOnColor
                onClicked: MediaService.previous()
            }
            WidgetButton {
                size: root.unit * 0.22; primary: true
                glyph: MediaService.playing ? "\ue034" : "\ue037"
                anchors.verticalCenter: parent.verticalCenter
                onColor: root.onColor; fillColor: root.onOnColor
                onClicked: MediaService.togglePlay()
            }
            WidgetButton {
                size: root.unit * 0.17; glyph: "\ue044"
                anchors.verticalCenter: parent.verticalCenter
                onColor: root.onColor; fillColor: root.onOnColor
                onClicked: MediaService.next()
            }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8; height: 4; radius: 2
            visible: MediaService.has
            color: Theme.alpha(root.onColor, 0.18)
            Rectangle {
                width: parent.width * MediaService.fraction; height: parent.height; radius: 2
                color: root.accentColor
                Behavior on width { MotionAnimation { role: "stateChange" } }
            }
        }
    }
}
