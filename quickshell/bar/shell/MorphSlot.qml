import "root:/theme"
import QtQuick

// Слот контенту MorphSurface: фіксований (цільовий) розмір по центру хоста, crossfade із
// затримкою на вході (контент з'являється, коли поверхня вже майже виросла).
Item {
    id: slot

    property Item host
    property bool shown: false
    property real slotWidth: 0
    property real slotHeight: 0

    width: slotWidth
    height: slotHeight
    x: host ? (host.width - width) / 2 : 0
    y: host ? (host.height - height) / 2 : 0
    opacity: shown ? 1 : 0
    enabled: shown

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: slot.shown ? Math.round(ThemeMotion.duration("morph") * 0.25) : 0 }
            MotionAnimation { role: slot.shown ? "enter" : "exit" }
        }
    }
}
