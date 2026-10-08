import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.DockApp

// Invisible click-catcher that sits on the full screen directly behind the
// dock (same Wayland layer; created before the dock window, so wlroots keeps
// the dock stacked above it). It exists because a dock context menu must
// close when the user clicks anywhere outside the dock — and a compositor
// focus grab (HyprlandFocusGrab) is not portable.
//
// It is input-transparent (empty mask) whenever no menu is open, so in
// normal use it never blocks clicks meant for the windows behind the dock.
// While a menu is open the mask covers the whole screen: any outside click
// lands here and dismisses the menu, and the dock above it still receives
// its own clicks normally. Escape is handled in DockWindow via exclusive
// layer-shell keyboard focus.
PanelWindow {
    id: catcher

    color: "transparent"
    visible: true

    Component.onCompleted: console.log("Dock: click-catcher created on",
        screen ? screen.name : "<no screen>")

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    // Never holds a gap open in the tiling layout, never takes keyboard.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property bool active: DockSettings.ready
        && DockSettings.enabled && DockSettings.menuOpen

    mask: Region {
        Region {
            x: 0
            y: 0
            width: catcher.active ? catcher.width : 0
            height: catcher.active ? catcher.height : 0
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: catcher.active
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: DockSettings.menuOpen = false
    }
}
