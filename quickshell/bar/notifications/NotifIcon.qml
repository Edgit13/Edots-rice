pragma ComponentBehavior: Bound
import "root:/theme"
import Quickshell
import QtQuick
import QtQuick.Effects

// NotifIcon — фото/іконка застосунку у squircle-бейджі; без іконки — літера застосунку.
Item {
    id: root
    required property var notif
    property bool critical: false

    readonly property bool isPhoto: !!notif.image && notif.image.length > 0
    readonly property string src: {
        const n = root.notif
        if (n.image && n.image.length > 0) return n.image
        let ic = n.appIcon || ""
        if (ic.length === 0) {
            const de = DesktopEntries.heuristicLookup(n.desktopEntry || n.appName || "")
            ic = de ? (de.icon || "") : ""
        }
        if (ic.length === 0) return ""
        if (ic.charAt(0) === "/") return "file://" + ic
        if (ic.indexOf("file:") === 0 || ic.indexOf("image:") === 0) return ic
        return Quickshell.iconPath(ic, true)
    }
    readonly property bool hasImg: img.status === Image.Ready

    // squircle: фото — більш квадратне, іконка — майже коло
    readonly property real shapeRadius: isPhoto ? Theme.shape.radius("md", height) : Theme.shape.radius("lg", height)

    Rectangle {
        anchors.fill: parent
        radius: root.shapeRadius
        color: root.critical ? (Theme.settings.nothing ? "transparent" : Theme.color.error)
             : (Theme.settings.nothing ? "transparent" : Theme.color.primaryContainer)
        // Nothing: контурна «плитка» іконки; критичне — червоний контур
        border.width: Theme.settings.nothing ? 1 : 0
        border.color: root.critical ? ThemeNothing.red : Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.28)
        visible: !root.isPhoto
        Behavior on color { MotionColorAnimation { role: "stateChange" } }
        ThemedText {
            anchors.centerIn: parent
            visible: !root.hasImg
            text: (root.notif.appName || "?").charAt(0).toUpperCase()
            style: Theme.type.titleMedium
            emphasized: true
            color: root.critical ? (Theme.settings.nothing ? ThemeNothing.red : Theme.color.fgError)
                 : (Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.fgPrimaryContainer)
        }
    }

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
        anchors.margins: root.isPhoto ? 0 : root.width * 0.18
        source: root.src
        fillMode: root.isPhoto ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        asynchronous: true
        sourceSize.width: 128
        sourceSize.height: 128
        opacity: root.hasImg ? 1 : 0
        Behavior on opacity { MotionAnimation { role: "enter" } }
        layer.enabled: root.isPhoto
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }
}
