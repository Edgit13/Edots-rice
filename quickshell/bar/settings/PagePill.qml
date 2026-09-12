pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Page extracted from the former SettingsPages.qml monolith (Phase 4 fix).

Item {
    id: pagePillRoot
    implicitHeight: pillCol.implicitHeight

    ColumnLayout {
        id: pillCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "Pill" }

        Card {
            title: "Geometry"

            SliderRow {
                category: "pill"; configKey: "idleHeight"
                label: "Idle height"; from: 20; to: 80; suffix: " px"
            }
            SliderRow {
                category: "pill"; configKey: "idleHorizontalPadding"
                label: "Idle horizontal padding"; from: 4; to: 60; suffix: " px"
            }
            SliderRow {
                category: "pill"; configKey: "idleTopMargin"
                label: "Top margin"; from: 0; to: 40; suffix: " px"
            }
            SliderRow {
                category: "pill"; configKey: "expandedWidth"
                label: "Expanded width"; from: 320; to: 1200; stepSize: 10; suffix: " px"
            }
            SliderRow {
                category: "pill"; configKey: "expandedHeight"
                label: "Expanded height"; from: 200; to: 900; stepSize: 10; suffix: " px"
            }
            SliderRow {
                category: "pill"; configKey: "expandedRadius"
                label: "Corner radius (surface open)"; from: 0; to: 60; suffix: " px"
            }
        }

        Card {
            title: "Style"

            SliderRow {
                category: "pill"; configKey: "backgroundOpacity"
                label: "Background opacity"; from: 0.3; to: 1.0
                stepSize: 0.01; decimals: 2
            }
            SliderRow {
                category: "pill"; configKey: "hoverScale"
                label: "Hover scale"; from: 1.0; to: 1.2
                stepSize: 0.01; decimals: 2
            }
            SliderRow {
                category: "pill"; configKey: "borderWidthDefault"
                label: "Border width"; from: 0; to: 6; suffix: " px"
            }
            SliderRow {
                category: "pill"; configKey: "borderWidthHover"
                label: "Border width (hover)"; from: 0; to: 8; suffix: " px"
            }
            SwitchRow {
                category: "pill"; configKey: "glowEnabled"
                label: "Accent glow"
                description: "Breathing accent border around the pill."
            }
            SliderRow {
                category: "pill"; configKey: "glowMinOpacity"
                label: "Glow minimum opacity"; from: 0.0; to: 1.0
                stepSize: 0.01; decimals: 2
            }
            SliderRow {
                category: "pill"; configKey: "glowMaxOpacity"
                label: "Glow maximum opacity"; from: 0.0; to: 1.0
                stepSize: 0.01; decimals: 2
            }
        }

        Card {
            title: "Animations"

            SliderRow {
                category: "pill"; configKey: "morphDuration"
                label: "Morph duration"; from: 0; to: 2000; stepSize: 20; suffix: " ms"
                description: "Idle <-> expanded size transition."
            }
            SliderRow {
                category: "pill"; configKey: "morphOvershoot"
                label: "Morph overshoot"; from: 0.5; to: 2.5
                stepSize: 0.05; decimals: 2
            }
            SliderRow {
                category: "pill"; configKey: "radiusTransitionDuration"
                label: "Radius transition"; from: 0; to: 1000; stepSize: 20; suffix: " ms"
            }
            SliderRow {
                category: "pill"; configKey: "scaleDuration"
                label: "Hover scale duration"; from: 0; to: 1000; stepSize: 20; suffix: " ms"
            }
            SliderRow {
                category: "pill"; configKey: "borderTransitionDuration"
                label: "Border transition"; from: 0; to: 1000; stepSize: 20; suffix: " ms"
            }
            SliderRow {
                category: "pill"; configKey: "glowBreathDuration"
                label: "Glow breathing cycle"; from: 400; to: 8000; stepSize: 100; suffix: " ms"
            }
        }
    }
}
