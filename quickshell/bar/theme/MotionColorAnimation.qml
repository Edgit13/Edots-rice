import "root:/theme"
import QtQuick

// ColorAnimation за роллю руху (див. MotionAnimation)
ColorAnimation {
    property string role: "stateChange"
    duration: ThemeMotion.duration(role)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: ThemeMotion.curveFor(role)
}
