import "root:/theme"
import QtQuick

// Слот контенту MorphSurface: фіксований розмір по центру хоста.
// Вхід: контент чекає, поки тіло вже майже виросло, тоді плавно проявляється, трохи піднімаючись
// знизу й збільшуючись (без overshoot). Вихід: швидко гасне ще ДО згортання тіла, щоб не вилазити за краї.
Item {
    id: slot

    property Item host
    property bool shown: false
    property real slotWidth: 0
    property real slotHeight: 0
    // з якого боку «прикріплений» контент (як origin тіла) і відступи по осях
    property real originX: 0.5
    property real originY: 0.5
    property real padX: 0
    property real padY: 0

    readonly property real _hiddenScale: ThemeMotion.reduced ? 1 : 0.96
    readonly property real _hiddenLift:  ThemeMotion.reduced ? 0 : 8

    width: slotWidth
    height: slotHeight
    // Контент тримається біля точки, що не рухається при рості тіла (origin), а не їде за його центром:
    // тіло «відкриває» контент, а не змітає його. У спокої (тіло = слот + padding) дає ту саму позицію, що й раніше.
    x: host ? padX + (host.width  - width  - padX * 2) * originX : 0
    y: host ? padY + (host.height - height - padY * 2) * originY : 0
    opacity: shown ? 1 : 0
    scale: shown ? 1.0 : _hiddenScale
    enabled: shown
    visible: opacity > 0.001

    transform: Translate {
        id: lift
        y: slot.shown ? 0 : slot._hiddenLift
        Behavior on y { MotionAnimation { role: slot.shown ? "contentIn" : "contentOut" } }
    }

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation { duration: slot.shown ? Math.round(ThemeMotion.duration("morphIn") * 0.35) : 0 }
            MotionAnimation { role: slot.shown ? "contentIn" : "contentOut" }
        }
    }
    Behavior on scale { MotionAnimation { role: slot.shown ? "contentIn" : "contentOut" } }
}
