import "root:/theme"
import "root:/services"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// DesktopWidgetsWindow — шар Background на кожному моніторі.
// Віджети або в авто-кластері вибраного кута, або вільно (позиція користувача); клік повз них проходить крізь.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    visible: WidgetsConfig.enabled
             && (WidgetsConfig.monitor === "" || WidgetsConfig.monitor === (screen ? screen.name : ""))
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "edots-widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }

    mask: Region {
        item: cluster
        Region { item: clockSlot.visible ? clockSlot : null }
        Region { item: weatherSlot.visible ? weatherSlot : null }
        Region { item: mediaSlot.visible ? mediaSlot : null }
        Region { item: resourcesSlot.visible ? resourcesSlot : null }
        Region { item: toolbar.visible ? toolbar : null }
    }

    readonly property real unit: Theme.components.dp(200) * WidgetsConfig.scale

    // вільні віджети
    Item { id: freeLayer; anchors.fill: parent }

    // авто-кластер
    GridLayout {
        id: cluster

        readonly property string a: WidgetsConfig.anchor
        readonly property bool atLeft: a.endsWith("left")
        readonly property bool atRight: a.endsWith("right")
        readonly property bool atTop: a.startsWith("top")
        readonly property bool atBottom: a.startsWith("bottom")
        readonly property real m: WidgetsConfig.margin

        x: atLeft ? m : atRight ? win.width - width - m : (win.width - width) / 2
        y: atTop ? m : atBottom ? win.height - height - m : (win.height - height) / 2
        columns: WidgetsConfig.arrange === "column" ? 1 : WidgetsConfig.arrange === "grid" ? 2 : 4
        rowSpacing: WidgetsConfig.spacing
        columnSpacing: WidgetsConfig.spacing
        opacity: WidgetsConfig.opacity
    }

    WidgetSlot {
        id: clockSlot
        kind: "clock"; layoutHost: cluster; freeHost: freeLayer; unit: win.unit
        visible: WidgetsConfig.clockEnabled
        opacity: free ? WidgetsConfig.opacity : 1
        ClockWidget { anchors.fill: parent; unit: win.unit }
    }
    WidgetSlot {
        id: weatherSlot
        kind: "weather"; layoutHost: cluster; freeHost: freeLayer; unit: win.unit
        visible: WidgetsConfig.weatherEnabled
        opacity: free ? WidgetsConfig.opacity : 1
        WeatherWidget { anchors.fill: parent; unit: win.unit }
    }
    WidgetSlot {
        id: mediaSlot
        kind: "media"; layoutHost: cluster; freeHost: freeLayer; unit: win.unit
        wFactor: 1.7
        visible: WidgetsConfig.mediaEnabled && (WidgetsConfig.editing || !WidgetsConfig.mediaHideIdle || MediaService.has)
        opacity: free ? WidgetsConfig.opacity : 1
        Layout.columnSpan: WidgetsConfig.arrange === "grid" ? 2 : 1
        MediaWidget { anchors.fill: parent; unit: win.unit }
    }
    WidgetSlot {
        id: resourcesSlot
        kind: "resources"; layoutHost: cluster; freeHost: freeLayer; unit: win.unit
        visible: WidgetsConfig.resourcesEnabled
        opacity: free ? WidgetsConfig.opacity : 1
        ResourcesWidget { anchors.fill: parent; unit: win.unit }
    }

    EditToolbar {
        id: toolbar
        z: 100
        anchors.horizontalCenter: parent.horizontalCenter
        y: 32
    }
}
