import "root:/theme"
import "root:/services"
import QtQuick
import QtQuick.Layouts

// WorkspaceStrip — теги монітора: Row (горизонтальний бар) або Column (вертикальний).
// Колесо миші — попередній/наступний тег.
//   WorkspaceStrip { monitor: win.monitorName; vertical: win.vertical; itemSize: win.cross - 8 }
Item {
    id: root

    property string monitor: ""
    property bool vertical: false
    property real itemSize: 24
    property real spacing: Theme.space.xxs

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid
        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, MangoService.tagCount(root.monitor))
        rowSpacing: root.spacing
        columnSpacing: root.spacing

        Repeater {
            model: MangoService.tagCount(root.monitor)
            WorkspaceItem {
                required property int index          // Repeater: 0-based
                tagIndex: index + 1                  // тег: 1-based
                monitor: root.monitor
                vertical: root.vertical
                size: root.itemSize
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (e) { MangoService.stepTag(root.monitor, e.angleDelta.y > 0 ? -1 : 1) }
    }
}
