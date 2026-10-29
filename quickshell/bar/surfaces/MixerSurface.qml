pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/settings"
import "root:/widgets"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// MixerSurface.qml — Material 3 Expressive (Android 16): товсті round-треки,
// великі ручки з drag, креативна розкладка: volume (hero) + row(brightness,
// battery-card). Логіка Pipewire/brightnessctl 1:1.
// ==========================================================================

Item {
    id: root

    property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.ready
    readonly property int vol: sinkReady ? Math.round(sink.audio.volume * 100) : 0

    readonly property bool nothing: Theme.settings.nothing
    property int brightnessVal: 50

    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val)) root.brightnessVal = val
            }
        }
    }
    Process { id: brightnessSetProc; command: [] }

    function setBrightness(val) {
        let clamped = Math.max(5, Math.min(100, val))
        root.brightnessVal = clamped
        brightnessSetProc.command = ["brightnessctl", "s", clamped + "%"]
        brightnessSetProc.running = true
    }

    Component.onCompleted: { if (!brightnessQuery.running) brightnessQuery.running = true }

    PwObjectTracker { objects: [root.sink] }

    // ---- M3 Expressive slider: товстий round-трек + велика ручка + drag ----
    component XSlider: RowLayout {
        id: xs
        property string icon: ""
        property color accent: Md.primary
        property real fraction: 0
        property string valueLabel: ""
        property bool big: false
        readonly property bool nothing: Theme.settings.nothing
        signal setFraction(real pct)

        Layout.fillWidth: true
        spacing: 10

        Text {
            visible: xs.icon.length > 0
            text: xs.icon
            color: xs.accent
            font { family: "Material Symbols Rounded"; pixelSize: 15 }
        }

        // ---- Nothing: сегментований слайдер (рядок «пігулок», що запалюються до значення) ----
        Item {
            id: seg
            visible: xs.nothing
            Layout.fillWidth: true
            Layout.preferredHeight: xs.nothing ? (xs.big ? 28 : 20) : 0
            readonly property int count: Math.max(8, Math.floor((width + 4) / 9))

            Row {
                anchors.fill: parent
                spacing: 5
                Repeater {
                    model: seg.count
                    delegate: Rectangle {
                        required property int index
                        readonly property bool lit: (index + 0.5) / seg.count <= xs.fraction
                        width: (seg.width - (seg.count - 1) * 5) / seg.count
                        height: xs.big ? 24 : 16
                        anchors.verticalCenter: parent.verticalCenter
                        radius: width / 2
                        color: lit ? xs.accent : Colors.fg
                        opacity: lit ? 1.0 : ThemeNothing.dotOpacityOff
                        Behavior on opacity { NumberAnimation { duration: 90 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onPressed: (m) => xs.setFraction(Math.max(0, Math.min(1, (m.x - 6) / seg.width)))
                onPositionChanged: (m) => { if (pressed) xs.setFraction(Math.max(0, Math.min(1, (m.x - 6) / seg.width))) }
            }
        }

        Rectangle {
            id: track
            visible: !xs.nothing
            Layout.fillWidth: true
            Layout.preferredHeight: xs.big ? 8 : 6
            radius: height / 2
            color: Md.surfaceContainerHighest

            Rectangle {
                width: track.width * xs.fraction
                height: parent.height
                radius: parent.radius
                color: xs.accent
            }

            Rectangle {
                id: handle
                width: xs.big ? 18 : 16
                height: width
                radius: width / 2
                x: track.width * xs.fraction - width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.fg
                border.width: 3
                border.color: xs.accent
                scale: trackMa.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: Md.durFast } }
            }

            MouseArea {
                id: trackMa
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: (m) => xs.setFraction(Math.max(0, Math.min(1, m.x / width)))
                onPositionChanged: (m) => { if (pressed) xs.setFraction(Math.max(0, Math.min(1, m.x / width))) }
            }
        }

        Text {
            text: xs.valueLabel
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
            font { family: Colors.monoFont; pixelSize: 11 }
            Layout.preferredWidth: 38
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ---- HERO: volume ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                visible: !root.nothing
                text: "\ue050"
                color: Md.primary
                font { family: "Material Symbols Rounded"; pixelSize: 18 }
            }
            Text {
                Layout.fillWidth: true
                text: root.nothing ? Lang.t("mixer.volume").toUpperCase() : Lang.t("mixer.volume")
                color: root.nothing ? Colors.grey1 : Colors.fg
                font {
                    family: root.nothing ? Theme.type.mono : Colors.uiFont
                    pixelSize: root.nothing ? 10 : 13
                    weight: root.nothing ? 400 : 600
                    letterSpacing: root.nothing ? 2.5 : 0
                }
            }
            Text {
                text: root.sinkReady ? root.vol + (root.nothing ? "" : "%") : "-"
                color: root.nothing ? Colors.fg : Md.primary
                font {
                    family: root.nothing ? Theme.type.dot : Colors.monoFont
                    pixelSize: root.nothing ? 30 : 14
                    weight: root.nothing ? 400 : 600
                }
            }
        }

        XSlider {
            big: true
            icon: ""
            fraction: root.vol / 100
            valueLabel: ""
            onSetFraction: (pct) => { if (root.sinkReady) root.sink.audio.volume = pct }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 2
            height: 1
            color: Md.outlineVariant
        }

        // ---- row: brightness + battery card ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            XSlider {
                Layout.fillWidth: true
                icon: "\ue3ab"
                accent: Md.error
                fraction: root.brightnessVal / 100
                valueLabel: root.brightnessVal + "%"
                onSetFraction: (pct) => root.setBrightness(Math.round(pct * 100))
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: batRow.implicitWidth + 20
                implicitHeight: batRow.implicitHeight + 14
                radius: root.nothing ? ThemeNothing.corners.sm : Md.rM
                color: root.nothing ? "transparent" : Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.6)
                border.width: root.nothing ? 1 : 0
                border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.18)

                RowLayout {
                    id: batRow
                    anchors.centerIn: parent
                    spacing: 6
                    Battery {}
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
