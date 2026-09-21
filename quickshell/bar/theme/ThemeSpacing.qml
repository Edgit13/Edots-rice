pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeSpacing — 4dp-сітка × uiScale.
Singleton {
    id: root

    readonly property real k: ThemeSettings.uiScale
    function dp(v) { return Math.round(v * k) }

    readonly property int none: 0
    readonly property int xxs: dp(2)
    readonly property int xs: dp(4)
    readonly property int sm: dp(8)
    readonly property int md: dp(12)
    readonly property int lg: dp(16)
    readonly property int xl: dp(24)
    readonly property int xxl: dp(32)
    readonly property int xxxl: dp(48)

    // ролі
    readonly property int gap: dp(8)
    readonly property int gapTight: dp(4)
    readonly property int listGap: dp(2)         // connected list (M3E)
    readonly property int padding: dp(16)
    readonly property int paddingCompact: dp(8)
    readonly property int section: dp(24)
    readonly property int screenMargin: dp(8)    // відступ бару/острова від краю екрана
    readonly property int touchTarget: dp(48)    // мінімальна зона натискання (accessibility)
}
