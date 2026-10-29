import "root:/theme"
import QtQuick
import QtQuick.Effects

// MediaArt — обкладинка з нормальним заокругленням (маска, а не clip) і морфом форми:
// грає → squircle, пауза → коло (morphOnPause).
Item {
    id: root

    property url source: ""
    property bool playing: true
    property bool morphOnPause: false
    property real baseRadius: Theme.shape.cardLarge
    property real iconSize: Theme.type.iconXL

    readonly property bool hasArt: img.status === Image.Ready
    property real shapeRadius: (!morphOnPause || playing) ? baseRadius : Math.min(width, height) / 2
    Behavior on shapeRadius { MotionAnimation { role: "morph" } }

    // fallback
    Rectangle {
        anchors.fill: parent
        radius: root.shapeRadius
        color: Theme.color.secondaryContainer
        Text {
            anchors.centerIn: parent
            visible: !root.hasArt
            text: "\ue405"
            font { family: Theme.type.icons; pixelSize: root.iconSize }
            color: Theme.color.fgSecondaryContainer
        }
    }

    // маска
    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: root.shapeRadius }
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: Math.max(64, Math.ceil(root.width * 2))
        sourceSize.height: Math.max(64, Math.ceil(root.height * 2))
        opacity: root.hasArt ? 1 : 0
        Behavior on opacity { MotionAnimation { role: "enter" } }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            saturation: Theme.settings.nothing ? -0.85 : 0.0     // Nothing: майже монохромна обкладинка
        }
    }

    // тонкий контур у Nothing
    Rectangle {
        anchors.fill: parent
        visible: Theme.settings.nothing
        radius: root.shapeRadius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.22)
    }
}
