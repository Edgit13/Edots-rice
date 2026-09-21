import "root:/theme"
import QtQuick

// NumberAnimation за роллю руху: enter | exit | expand | collapse | morph | move | press | hover | stateChange | fade
NumberAnimation {
    property string role: "stateChange"
    duration: ThemeMotion.duration(role)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: ThemeMotion.curveFor(role)
}
