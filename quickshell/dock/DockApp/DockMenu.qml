import QtQuick
import QtQuick.Effects
import qs.DockApp

// M3 menu shown above a dock item on right click: elevated container with
// 8dp corners, entries as text rows on a primary state layer when hovered.
//
// This is a plain Item living inside the dock's own window, not a PopupWindow:
// while the dock holds a compositor focus grab (which is what closes the menu
// on an outside click), pointer input only reaches the grabbed layer surface,
// so a separate popup surface renders but never receives the clicks on its
// entries. DockWindow grows its window and widens its input mask to make room
// for it.
//
// The entries are handed in as a list of
//   { "label": "Pin to Dock", "callback": function () { ... } }
// objects; running a callback closes the menu.
Item {
    id: menu

    property var actions: []
    // Fixed width: sizing the menu to its longest label would make the rows'
    // width depend on the background, whose width depends on the rows — a
    // layout polish loop. The entries are short and known, so a constant is
    // enough (labels elide if a future one is longer).
    property int menuWidth: 200

    signal closeRequested()

    implicitWidth: menu.menuWidth
    implicitHeight: menuColumn.implicitHeight + 16
    width: implicitWidth
    height: implicitHeight
    visible: false

    // M3 elevation on the menu container.
    RectangularShadow {
        anchors.fill: menuBg
        radius: menuBg.radius
        blur: 12
        color: Qt.rgba(DockTheme.shadow.r, DockTheme.shadow.g, DockTheme.shadow.b, 0.4)
    }

    Rectangle {
        id: menuBg
        anchors.fill: parent
        radius: 8
        color: DockTheme.surface_container_high

        Column {
            id: menuColumn
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 2

            Repeater {
                model: menu.actions

                delegate: Rectangle {
                    id: row
                    required property var modelData

                    width: menuColumn.width
                    height: 36
                    radius: 6
                    // M3 menu item hover: primary state layer at 10%.
                    color: rowMouse.containsMouse
                        ? DockTheme.stateLayer(DockTheme.primary, 0.10)
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutQuint }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: row.modelData.label
                        color: DockTheme.on_surface
                        font.family: DockTheme.fontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        width: parent.width - 20
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Grab the callback before closing: closing clears
                            // the model and tears this delegate down, so reading
                            // modelData afterwards is not safe. The action runs
                            // after the menu is gone, since it may rebuild the
                            // dock items underneath it.
                            const run = row.modelData.callback
                            menu.closeRequested()
                            Qt.callLater(run)
                        }
                    }
                }
            }
        }
    }
}
