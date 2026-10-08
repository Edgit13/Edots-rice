import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.DockApp

// One app in the dock: its icon, an M3 active indicator pill behind it, a
// tooltip with the app name and a right-click menu to pin or unpin it.
Item {
    id: item

    // { key, appId, desktopEntry, name, iconSource, windows, pinned } — built by
    // DockWindow, which owns the desktop-entry lookup.
    property var entry: null
    property int iconSize: 32
    // The dock window. It owns the (single) context menu, which is drawn inside
    // its own surface — see DockMenu for why it is not a popup window.
    property var dockWindow: null

    // Whether the open context menu belongs to this item.
    readonly property bool menuOpen: item.dockWindow
        && item.dockWindow.menuItem === item

    signal pinRequested(string key)
    signal unpinRequested(string key)

    readonly property var windows: item.entry ? item.entry.windows : []
    readonly property bool running: item.windows.length > 0
    readonly property bool pinned: item.entry ? item.entry.pinned : false
    readonly property var desktopEntry: item.entry ? item.entry.desktopEntry : null
    readonly property string appName: item.entry ? item.entry.name : ""
    readonly property string iconSource: item.entry ? item.entry.iconSource : ""

    // Whether one of this app's windows is the focused one.
    readonly property bool active: {
        const focused = ToplevelManager.activeToplevel
        if (!focused)
            return false
        for (let i = 0; i < item.windows.length; i++)
            if (item.windows[i] === focused)
                return true
        return false
    }

    readonly property bool highlighted: itemMouse.containsMouse || item.menuOpen

    implicitWidth: item.iconSize + 16
    implicitHeight: item.iconSize + 18

    // --- ACTIONS ---
    function launch(): void {
        if (item.desktopEntry) {
            item.desktopEntry.execute()
            return
        }
        // No desktop entry (e.g. a pinned id inherited from another dock whose
        // app ships none): run the id as a command, which is what that id is.
        if (item.entry && item.entry.appId)
            Quickshell.execDetached(["bash", "-c", item.entry.appId])
    }

    // Focus the app: its only window, or — when it has several — the one after
    // the currently focused one, so repeated clicks cycle through them.
    function activate(): void {
        if (!item.running) {
            item.launch()
            return
        }
        if (item.windows.length === 1) {
            item.windows[0].activate()
            return
        }
        let index = -1
        const focused = ToplevelManager.activeToplevel
        for (let i = 0; i < item.windows.length; i++)
            if (item.windows[i] === focused)
                index = i
        item.windows[(index + 1) % item.windows.length].activate()
    }

    function closeWindows(): void {
        // Copy first: closing mutates the toplevel list this array comes from.
        const list = item.windows.slice()
        for (let i = 0; i < list.length; i++)
            list[i].close()
    }

    // Entries for the right-click menu, rebuilt each time it opens.
    function menuActions(): var {
        let actions = []
        if (item.pinned)
            actions.push({ "label": "Unpin from Dock",
                           "callback": () => item.unpinRequested(item.entry.key) })
        else
            actions.push({ "label": "Pin to Dock",
                           "callback": () => item.pinRequested(item.entry.key) })
        actions.push({ "label": item.running ? "New Window" : "Launch",
                       "callback": () => item.launch() })
        if (item.running)
            actions.push({ "label": item.windows.length > 1
                               ? "Close All Windows" : "Close Window",
                           "callback": () => item.closeWindows() })
        return actions
    }

    // --- M3 ACTIVE INDICATOR ---
    // The M3 navigation-bar indicator: a fully-rounded pill behind the icon.
    // secondary_container while the app is merely running, primary_container
    // while one of its windows is focused.
    Rectangle {
        id: activePill
        anchors.centerIn: iconImage
        width: item.iconSize + 24
        height: item.iconSize + 8
        radius: height / 2
        color: item.active ? DockTheme.primary_container
                           : DockTheme.secondary_container
        opacity: item.running ? (item.active ? 1 : 0.55) : 0
        scale: item.active ? 1 : 0.85

        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
    }

    // --- M3 STATE LAYER ---
    // The hover/focus/pressed layer M3 draws over interactive elements:
    // primary at 8% (hover), 10% (focus), 12% (pressed).
    // Same pill geometry as the active indicator, so the background always
    // matches the icon size whether the app is running (indicator pill) or
    // merely hovered (state layer).
    Rectangle {
        id: stateLayer
        anchors.centerIn: iconImage
        width: item.iconSize + 24
        height: item.iconSize + 8
        radius: height / 2
        color: DockTheme.primary
        opacity: itemMouse.pressed ? 0.12
               : item.highlighted ? 0.08 : 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
        }
    }

    Image {
        id: iconImage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // The icon sits a touch above the true centre so the running indicator
        // behind it does not feel cramped.
        anchors.verticalCenterOffset: -2
        source: item.iconSource
        width: item.iconSize
        height: item.iconSize
        sourceSize.width: item.iconSize * 2
        sourceSize.height: item.iconSize * 2
        fillMode: Image.PreserveAspectFit
        // Pinned apps that are not running are dimmed, like in nwg-dock.
        opacity: item.running ? 1 : 0.55
        scale: itemMouse.pressed ? 0.9 : (item.highlighted ? 1.08 : 1)

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                item.activate()
            } else if (mouse.button === Qt.MiddleButton) {
                item.launch()
            } else if (mouse.button === Qt.RightButton) {
                if (!item.dockWindow)
                    return
                // A second right click on the same icon closes the menu again.
                if (item.menuOpen) {
                    item.dockWindow.closeMenu()
                    return
                }
                tooltipTimer.stop()
                tooltip.visible = false
                item.dockWindow.openMenuFor(item, item.menuActions())
            }
        }

        onEntered: tooltipTimer.restart()
        onExited: {
            tooltipTimer.stop()
            tooltip.visible = false
        }
    }

    // --- TOOLTIP ---
    Timer {
        id: tooltipTimer
        interval: 400
        onTriggered: {
            if (itemMouse.containsMouse && !item.menuOpen)
                tooltip.visible = true
        }
    }

    PopupWindow {
        id: tooltip

        color: "transparent"
        implicitWidth: tooltipBg.implicitWidth
        implicitHeight: tooltipBg.implicitHeight

        // A partial anchor.rect collapses the anchor rectangle and the popup
        // never shows — the gap has to come from margins (see DockMenu).
        anchor.item: item
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        anchor.margins.bottom: 6

        // M3 plain tooltip: inverse container (on_surface) with the background
        // color as text, 8dp corners, no border.
        Rectangle {
            id: tooltipBg
            anchors.centerIn: parent
            implicitWidth: tooltipText.implicitWidth + 20
            implicitHeight: tooltipText.implicitHeight + 12
            radius: 8
            color: DockTheme.on_surface

            RectangularShadow {
                anchors.fill: parent
                radius: parent.radius
                blur: 8
                color: Qt.rgba(DockTheme.shadow.r, DockTheme.shadow.g, DockTheme.shadow.b, 0.35)
            }

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: item.windows.length > 1
                    ? item.appName + " (" + item.windows.length + ")"
                    : item.appName
                color: DockTheme.background
                font.family: DockTheme.fontFamily
                font.pixelSize: 14
            }
        }
    }

}
