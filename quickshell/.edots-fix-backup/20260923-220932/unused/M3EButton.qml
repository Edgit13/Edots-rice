pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// M3EButton.qml — Material 3 Expressive кнопка: морфинг форми pill->cookie
// при натисканні (spring), state layers, опційний ripple, іконка+лейбл.
Item {
    id: eb
    property string text: ""
    property string icon: ""
    property string style: "filled"      // filled | tonal | outlined | text
    property bool enabled_: true
    signal clicked()

    readonly property bool iconOnly: text.length === 0
    implicitWidth: iconOnly ? 44 : Math.max(64, row.implicitWidth + 28)
    implicitHeight: iconOnly ? 44 : 38

    readonly property color _fg: {
        if (style === "tonal") return Md.onSurface
        if (style === "outlined" || style === "text") return Md.primary
        return Md.onPrimary
    }

    // spring-стан морфу: 0 = pill, 1 = cookie(lobed4)
    property real morph: 0
    NumberAnimation {
        id: morphAnim
        target: eb
        property: "morph"
        easing.type: Easing.OutBack
        easing.overshoot: 2.2
        duration: 380
    }
    function setMorph(v) {
        morphAnim.to = v
        morphAnim.restart()
    }

    readonly property color _bg: {
        switch (style) {
        case "tonal": return Md.secondaryContainer
        case "outlined": return Md.surfaceContainer
        case "text": return "transparent"
        default: return Md.primary
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        // icon-only: квадратна кнопка з морфом коло->cookie
        MorphShape {
            visible: eb.iconOnly
            anchors.centerIn: parent
            size: Math.min(parent.width, parent.height)
            color: {
                if (!eb.enabled_) return Md.surfaceContainerHigh
                if (ebMa.pressed) return Md.pressedOf(eb._bg)
                if (ebMa.containsMouse) return Md.hoverOf(eb._bg)
                return eb.style === "outlined" && !ebMa.containsMouse ? "transparent" : eb._bg
            }
            shape: 6
            shapeTo: 5
            progress: eb.morph
            rotationDeg: eb.morph * 18
        }

        // текстова: stadium pill (морф — легкий scale)
        Rectangle {
            visible: !eb.iconOnly
            anchors.fill: parent
            radius: height / 2
            scale: 1 - eb.morph * 0.06
            color: {
                if (!eb.enabled_) return Md.surfaceContainerHigh
                if (ebMa.pressed) return Md.pressedOf(eb._bg)
                if (ebMa.containsMouse) return Md.hoverOf(eb._bg)
                return eb._bg
            }
            border.width: eb.style === "outlined" ? 1 : 0
            border.color: Md.outline
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Ripple { id: rip; anchors.fill: parent; color: eb._fg }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: eb.icon.length > 0
            text: eb.icon
            color: eb._fg
            font { family: "Material Symbols Rounded"; pixelSize: 17 }
        }
        Text {
            visible: eb.text.length > 0
            text: eb.text
            color: eb._fg
            font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
        }
    }

    MouseArea {
        id: ebMa
        anchors.fill: parent
        hoverEnabled: true
        enabled: eb.enabled_
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: (m) => { eb.setMorph(1); rip.burst(m.x, m.y) }
        onReleased: eb.setMorph(0)
        onCanceled: eb.setMorph(0)
        onClicked: eb.clicked()
    }
}
