import "root:/theme"
import "root:/settings"
import "root:/services"
import "root:/media"
import QtQuick

// MediaModule — M3 Expressive міні-плеєр у барі (MPRIS).
// Кільце прогресу з іконкою play/pause + «виконавець — назва».
// Клік: Play/Pause; правий клік: Next; середній: відкрити Media surface; колесо: prev/next.
// Автоматично ховається, якщо нічого не грає.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal mediaRequested()

    readonly property bool hasMedia: MediaService.has && (MediaService.title.length > 0 || MediaService.playing)
    readonly property string displayTrack: MediaService.artist.length > 0
        ? (MediaService.artist + " — " + MediaService.title)
        : (MediaService.title || Lang.t("ui.media.title"))
    readonly property real ringSize: Math.max(Theme.components.dp(20), cross - Theme.space.md)

    visible: hasMedia
    implicitWidth: hasMedia ? (vertical ? cross : Math.min(Theme.components.dp(240), contentRow.implicitWidth + Theme.space.sm * 2)) : 0
    implicitHeight: hasMedia ? (vertical ? (ringSize + Theme.space.xs * 2 + Theme.space.sm) : cross) : 0

    Behavior on implicitWidth { MotionAnimation { role: "morph" } }
    Behavior on implicitHeight { MotionAnimation { role: "morph" } }

    // позиція в MPRIS сама не оновлюється
    Timer {
        interval: 500
        repeat: true
        running: root.visible && MediaService.playing
        onTriggered: MediaService.poll()
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: ma.pressed ? Math.min(width, height) * 0.28
              : Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
             : "transparent"

        scale: ma.pressed ? 0.95 : 1.0
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            MediaRing {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: root.ringSize
                implicitHeight: root.ringSize
                width: root.ringSize
                height: root.ringSize
                value: MediaService.fraction
                icon: MediaService.playing ? "\ue034" : "\ue037"
                ringColor: Theme.color.primary
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayTrack
                style: Theme.type.labelMedium
                color: Theme.color.fgSurface
                elide: Text.ElideRight
                width: Math.min(Theme.components.dp(160), implicitWidth)
            }
        }

        MediaRing {
            visible: root.vertical
            anchors.centerIn: parent
            width: root.ringSize
            height: root.ringSize
            value: MediaService.fraction
            icon: MediaService.playing ? "\ue034" : "\ue037"
            ringColor: Theme.color.primary
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) MediaService.next()
            else if (mouse.button === Qt.MiddleButton) root.mediaRequested()
            else MediaService.togglePlay()
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (event.angleDelta.y > 0) MediaService.previous()
            else MediaService.next()
        }
    }
}
