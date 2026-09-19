pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick

// M3EIconButton.qml — Expressive icon-кнопка: коло МОРФИТЬ у cookie/pentagon
// на press (spring), ripple, state layers. style: standard|filled|tonal.
Item {
    id: ib
    property string icon: ""
    property string style: "standard"
    property bool enabled_: true
    signal clicked()

    width: 38
    height: 38

    readonly property color _fg: style === "filled" ? Md.onPrimary
        : style === "tonal" ? Md.onSurface : Md.primary
    readonly property color _bg: style === "filled" ? Md.primary
        : style === "tonal" ? Md.secondaryContainer : Md.surfaceContainerHigh

    property real morph: 0
    NumberAnimation {
        id: morphAnim
        target: ib
        property: "morph"
        easing.type: Easing.OutBack
        easing.overshoot: 2.4
        duration: 400
    }
    function setMorph(v) { morphAnim.to = v; morphAnim.restart() }

    MorphShape {
        anchors.centerIn: parent
        size: 38
        shape: 6                       // oval (коло)
        shapeTo: 5                     // cookie4
        progress: ib.morph
        rotationDeg: ib.morph * 20
        color: {
            if (!ib.enabled_) return Md.surfaceContainerHigh
            if (ibMa.pressed) return Md.pressedOf(ib._bg)
            if (ibMa.containsMouse) return Md.hoverOf(ib._bg)
            return style === "standard" && !ibMa.containsMouse ? "transparent" : ib._bg
        }
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        anchors.centerIn: parent
        text: ib.icon
        color: ib._fg
        font { family: "Material Symbols Rounded"; pixelSize: 19 }
        scale: ibMa.pressed ? 0.85 : 1.0
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
    }

    Ripple { id: rip; anchors.fill: parent; color: ib._fg }

    MouseArea {
        id: ibMa
        anchors.fill: parent
        hoverEnabled: true
        enabled: ib.enabled_
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: (m) => { ib.setMorph(1); rip.burst(m.x, m.y) }
        onReleased: ib.setMorph(0)
        onCanceled: ib.setMorph(0)
        onClicked: ib.clicked()
    }
}
