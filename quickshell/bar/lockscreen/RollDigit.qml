import QtQuick

// RollDigit — цифра, що плавно «перегортається» (старе значення виїжджає вгору й гасне, нове піднімається знизу).
Item {
    id: dg

    property string value: "0"
    property int px: 100
    property color tint: "white"
    property string fam: ""

    property string shown: value
    property string prev: value
    property real t: 1
    property bool ready: false

    implicitWidth: probe.implicitWidth
    implicitHeight: probe.implicitHeight
    clip: true

    Component.onCompleted: ready = true
    onValueChanged: {
        if (!ready) { shown = value; prev = value; return }
        prev = shown
        shown = value
        t = 0
        roll.restart()
    }

    NumberAnimation { id: roll; target: dg; property: "t"; from: 0; to: 1; duration: 620; easing.type: Easing.OutCubic }

    Text { id: probe; visible: false; text: "0"; font { family: dg.fam; pixelSize: dg.px } }
    Text {
        text: dg.prev
        color: dg.tint
        opacity: 1 - dg.t
        y: -dg.t * dg.height * 0.5
        font { family: dg.fam; pixelSize: dg.px }
    }
    Text {
        text: dg.shown
        color: dg.tint
        opacity: dg.t
        y: (1 - dg.t) * dg.height * 0.5
        font { family: dg.fam; pixelSize: dg.px }
    }
}
