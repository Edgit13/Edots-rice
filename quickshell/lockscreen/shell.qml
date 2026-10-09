//@ pragma UseQApplication
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Shared Material 3 foundation (colors.json is watched inside M3.qml).
import "material"

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property bool authenticating: false
    property bool showPassword: false
    property int errorCount: 0

    // ---- animation / event tickers (visible to every surface) ----
    property real parallaxX: 0
    property real parallaxY: 0
    property int  shakeTick: 0
    property int  successTick: 0

    function clamp01(v) { return v < 0 ? 0 : (v > 1 ? 1 : v) }

    // Full M3 Expressive shape catalog (from the reference PNG).
    readonly property var dotCatalog: [
        "cookie", "sunny", "burst", "star",
        "clover", "flower", "pentagon", "hexagon",
        "square", "oval", "pill", "pill_diag",
        "blob", "circle"
    ]

    // Ambient floating shapes: shape / size / initial pos / drift
    readonly property var floaters: [
        { shape: "blob",    size: 260, x: 0.08, y: 0.18, ax: 0.05, ay: 0.02, dur: 32000 },
        { shape: "cookie",  size: 200, x: 0.82, y: 0.28, ax: 0.05, ay: 0.03, dur: 38000 },
        { shape: "flower",  size: 180, x: 0.72, y: 0.78, ax: 0.04, ay: 0.04, dur: 42000 }
    ]

    FileView {
        id: wallpaperFile
        path: Quickshell.shellPath("../current-wallpaper.txt")
        watchChanges: true
    }

    property string wallpaperPath: {
        try {
            var p = wallpaperFile.text().trim()
            return p.length > 0 ? p : ""
        } catch (e) { return "" }
    }
    property string wallpaperUrl: wallpaperPath.length > 0 ? "file://" + wallpaperPath : ""

    readonly property string greeting: {
        var h = new Date().getHours()
        if (h < 5)  return "Good night"
        if (h < 12) return "Good morning"
        if (h < 18) return "Good afternoon"
        return "Good evening"
    }
    readonly property string greetingIcon: {
        var h = new Date().getHours()
        if (h < 5)  return "bedtime"
        if (h < 12) return "wb_sunny"
        if (h < 18) return "wb_twilight"
        return "dark_mode"
    }

    // ---------------------------------------------------------------- auth
    Process {
        id: authProc
        stdinEnabled: true
        property string pendingPassword: ""
        onStarted: write(pendingPassword + "\n")
        onExited: (exitCode, exitStatus) => {
            root.authenticating = false
            root.statusWorking = false
            if (exitCode === 0) {
                root.successTick += 1
                lock.locked = false
            } else {
                root.errorCount += 1
                root.statusError = true
                root.shakeTick += 1
            }
        }
    }

    Process { id: powerProc }

    property string passText: ""
    property bool statusWorking: false
    property bool statusError: false
    property var powerExec: []

    function tryUnlock() {
        if (root.authenticating || passText.length === 0) return
        root.authenticating = true
        root.statusError = false
        root.statusWorking = true
        authProc.pendingPassword = root.passText
        root.passText = ""
        authProc.exec([root.home + "/.config/quickshell/lockscreen/pam-auth"])
    }

    function runPower(cmd) { powerProc.exec(cmd) }

    // ------------------------------------------------------------- session
    WlSessionLock {
        id: lock
        locked: true
        onSecureChanged: if (!secure) quitTimer.start()

        WlSessionLockSurface {
            id: surf
            color: M3.surface

            Component.onCompleted: passField.forceActiveFocus()

            // ============ BACKGROUND LAYER (Ken Burns + parallax) ============
            Item {
                id: wallpaperLayer

                readonly property int overscan: 60
                width:  surf.width  + overscan * 2
                height: surf.height + overscan * 2
                x: -overscan - root.parallaxX * 16
                y: -overscan - root.parallaxY * 16
                transformOrigin: Item.Center

                // Ken Burns: slow breathing zoom
                property real kbScale: 1.0
                SequentialAnimation on kbScale {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 1.0; to: 1.05
                        duration: 22000
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: 1.05; to: 1.0
                        duration: 22000
                        easing.type: Easing.InOutSine
                    }
                }
                scale: kbScale

                Image {
                    id: wallpaper
                    anchors.fill: parent
                    source: root.wallpaperUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: wallpaper
                    blurEnabled: true
                    blur: 0.35
                    blurMax: 32
                    visible: wallpaper.status === Image.Ready
                }
            }

            // Tint + gradient wash (over the wallpaper)
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(M3.surface.r, M3.surface.g, M3.surface.b,
                               wallpaper.status === Image.Ready ? 0.55 : 0.90)
                Behavior on color { ColorAnimation { duration: M3.durSlow } }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(M3.primary.r, M3.primary.g, M3.primary.b, 0.10)
                    }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(M3.tertiary.r, M3.tertiary.g, M3.tertiary.b, 0.10)
                    }
                }
            }

            // ============ FLOATING AMBIENT SHAPES ============
            Repeater {
                model: root.floaters
                delegate: Item {
                    required property var modelData

                    anchors.fill: parent
                    z: 0

                    readonly property real baseX: surf.width  * modelData.x - modelData.size / 2
                    readonly property real baseY: surf.height * modelData.y - modelData.size / 2

                    ExpressiveDot {
                        id: floater
                        x: parent.baseX
                        y: parent.baseY
                        dotSize: modelData.size
                        shape: modelData.shape
                        dotColor: M3.primary
                        opacity: 0.055
                        rotation: 0

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: parent.baseX - surf.width  * modelData.ax
                                to:   parent.baseX + surf.width  * modelData.ax
                                duration: modelData.dur
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: parent.baseX + surf.width  * modelData.ax
                                to:   parent.baseX - surf.width  * modelData.ax
                                duration: modelData.dur
                                easing.type: Easing.InOutSine
                            }
                        }
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: parent.baseY - surf.height * modelData.ay
                                to:   parent.baseY + surf.height * modelData.ay
                                duration: modelData.dur * 0.8
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: parent.baseY + surf.height * modelData.ay
                                to:   parent.baseY - surf.height * modelData.ay
                                duration: modelData.dur * 0.8
                                easing.type: Easing.InOutSine
                            }
                        }
                        SequentialAnimation on rotation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0; to: 360
                                duration: modelData.dur * 4
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }
            }

            // Accent hairline
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 3
                color: M3.primary
            }

            // Click-anywhere: refocus + parallax tracking
            MouseArea {
                id: bgMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                onClicked: passField.forceActiveFocus()
                onPositionChanged: {
                    root.parallaxX = (mouseX / width  - 0.5) * 2
                    root.parallaxY = (mouseY / height - 0.5) * 2
                }
                onExited: { root.parallaxX = 0; root.parallaxY = 0 }
            }

            // ============ HERO CLOCK ============
            Column {
                id: clockCol
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.08
                spacing: M3.s12

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0

                    Text {
                        id: hourText
                        text: Qt.formatDateTime(clockTimer.date, "hh")
                        color: M3.m3OnSurface
                        font {
                            family: M3.fontFamily
                            pixelSize: Math.round(surf.height * 0.13)
                            weight: Font.Light
                        }
                        onTextChanged: hourPulse.restart()
                        SequentialAnimation {
                            id: hourPulse
                            NumberAnimation {
                                target: hourText; property: "opacity"
                                from: 0.35; to: 1.0
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    Text {
                        text: ":"
                        color: M3.primary
                        font {
                            family: M3.fontFamily
                            pixelSize: Math.round(surf.height * 0.13)
                            weight: Font.Light
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 1200; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.00; duration: 1200; easing.type: Easing.InOutQuad }
                        }
                    }
                    Text {
                        id: minText
                        text: Qt.formatDateTime(clockTimer.date, "mm")
                        color: M3.m3OnSurface
                        font {
                            family: M3.fontFamily
                            pixelSize: Math.round(surf.height * 0.13)
                            weight: Font.Light
                        }
                        onTextChanged: minPulse.restart()
                        SequentialAnimation {
                            id: minPulse
                            NumberAnimation {
                                target: minText; property: "opacity"
                                from: 0.35; to: 1.0
                                duration: 320
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clockTimer.date, "dddd, d MMMM")
                    color: M3.m3OnSurfaceVariant
                    font {
                        family: M3.fontFamily
                        pixelSize: 18
                        weight: Font.Medium
                        letterSpacing: 1.5
                    }
                }

                // Greeting pill with gentle float
                Rectangle {
                    id: greetPill
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: greetRow.implicitWidth + M3.s24
                    implicitHeight: 36
                    radius: M3.rFull
                    color: M3.secondaryContainer

                    property real floatY: 0
                    SequentialAnimation on floatY {
                        loops: Animation.Infinite
                        NumberAnimation { from: -3; to: 3; duration: 2600; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 3; to: -3; duration: 2600; easing.type: Easing.InOutSine }
                    }
                    transform: Translate { y: greetPill.floatY }

                    Row {
                        id: greetRow
                        anchors.centerIn: parent
                        spacing: M3.s8
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.greetingIcon
                            color: M3.m3OnSecondaryContainer
                            font { family: "Material Symbols Rounded"; pixelSize: 16 }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.greeting
                            color: M3.m3OnSecondaryContainer
                            font: M3.labelLarge
                        }
                    }
                }
            }

            Timer {
                id: clockTimer
                property var date: new Date()
                interval: 1000; running: true; repeat: true
                onTriggered: date = new Date()
            }

            // ============ MAIN CARD ============
            Rectangle {
                id: card
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 110
                width: Math.min(440, parent.width - 48)
                height: cardCol.implicitHeight + M3.s24 * 2
                radius: 32
                color: Qt.rgba(M3.surfaceContainerHigh.r,
                               M3.surfaceContainerHigh.g,
                               M3.surfaceContainerHigh.b, 0.94)

                // border pulse
                property real borderPulse: 0.6
                border.width: 1
                border.color: Qt.rgba(M3.outlineVariant.r,
                                      M3.outlineVariant.g,
                                      M3.outlineVariant.b,
                                      card.borderPulse)
                SequentialAnimation on borderPulse {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.35; to: 0.75; duration: 3400; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.75; to: 0.35; duration: 3400; easing.type: Easing.InOutSine }
                }

                // reveal driver 0 → 1
                property real reveal: 0

                opacity: 0.0
                scale: 0.94
                Component.onCompleted: {
                    enterAnim.start()
                    revealAnim.start()
                }
                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation {
                        target: card; property: "opacity"; to: 1.0
                        duration: 400; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: card; property: "scale"; to: 1.0
                        duration: 550
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }
                NumberAnimation {
                    id: revealAnim
                    target: card
                    property: "reveal"
                    from: 0.0; to: 1.0
                    duration: 950
                    easing.type: Easing.OutCubic
                }

                // shake (triggered by root.shakeTick)
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -9; duration: 45 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to:  9; duration: 60 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6; duration: 50 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to:  6; duration: 50 }
                    NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to:  0; duration: 60 }
                }

                // error halo (over the pill area) — flash on error
                Connections {
                    target: root
                    function onShakeTickChanged() {
                        shakeAnim.restart()
                        errFlashAnim.restart()
                    }
                    function onSuccessTickChanged() {
                        successFlashAnim.restart()
                    }
                }

                Column {
                    id: cardCol
                    anchors {
                        left: parent.left; right: parent.right; top: parent.top
                        margins: M3.s24
                    }
                    spacing: M3.s16

                    // ---- concentric avatar with rotating outer ring ----
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96; height: 96

                        opacity: root.clamp01(card.reveal * 4)
                        scale: 0.4 + 0.6 * root.clamp01(card.reveal * 4)
                        transform: Translate {
                            y: (1 - root.clamp01(card.reveal * 4)) * 14
                        }

                        // Outer ring rotates slowly
                        Rectangle {
                            id: outerRing
                            anchors.fill: parent
                            radius: M3.rFull
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(M3.primary.r, M3.primary.g, M3.primary.b, 0.35)
                            transformOrigin: Item.Center
                            SequentialAnimation on rotation {
                                loops: Animation.Infinite
                                NumberAnimation { from: 0; to: 360; duration: 24000; easing.type: Easing.Linear }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: M3.rFull
                            color: M3.tertiaryContainer
                            opacity: 0.55
                            scale: 1.0
                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.06; duration: 2400; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.06; to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 88; height: 88
                            radius: M3.rFull
                            color: M3.secondaryContainer
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 76; height: 76
                            radius: M3.rFull
                            color: M3.primary
                            Text {
                                anchors.centerIn: parent
                                text: (Quickshell.env("USER") || "u").substring(0, 1).toUpperCase()
                                color: M3.m3OnPrimary
                                font {
                                    family: M3.fontFamily
                                    pixelSize: 36
                                    weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    // ---- username ----
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Quickshell.env("USER")
                        color: M3.m3OnSurface
                        font {
                            family: M3.fontFamily
                            pixelSize: 22
                            weight: Font.Medium
                        }
                        opacity: root.clamp01((card.reveal - 0.15) * 4)
                        transform: Translate {
                            y: (1 - root.clamp01((card.reveal - 0.15) * 4)) * 14
                        }
                    }

                    // ============ PASSWORD PILL ============
                    Rectangle {
                        id: passWrap
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(340, parent.width - M3.s12)
                        height: 56
                        radius: M3.rFull
                        clip: true
                        color: passField.activeFocus
                             ? M3.surfaceContainerHighest
                             : M3.surfaceContainer
                        border.width: passField.activeFocus ? 2 : 1
                        border.color: passField.activeFocus
                             ? M3.primary
                             : (root.statusError ? M3.error : M3.outline)
                        Behavior on border.color { ColorAnimation { duration: M3.durFast } }
                        Behavior on color        { ColorAnimation { duration: M3.durFast } }

                        opacity: root.clamp01((card.reveal - 0.30) * 4)
                        transform: Translate {
                            y: (1 - root.clamp01((card.reveal - 0.30) * 4)) * 14
                        }

                        // breathing focus halo
                        Rectangle {
                            id: pillHalo
                            anchors.fill: parent
                            anchors.margins: -3
                            radius: parent.radius + 3
                            color: "transparent"
                            border.width: passField.activeFocus ? 3 : 0
                            border.color: Qt.rgba(M3.primary.r, M3.primary.g, M3.primary.b, 0.30)
                            z: -1
                            opacity: 0
                            Behavior on opacity { NumberAnimation { duration: M3.durMed } }
                            SequentialAnimation on opacity {
                                running: passField.activeFocus
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.15; duration: 1400; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.55; duration: 1400; easing.type: Easing.InOutSine }
                            }
                        }

                        // error flash
                        Rectangle {
                            id: errHalo
                            anchors.fill: parent
                            anchors.margins: -4
                            radius: parent.radius + 4
                            color: "transparent"
                            border.width: 3
                            border.color: M3.error
                            opacity: 0
                            z: -1
                            SequentialAnimation {
                                id: errFlashAnim
                                NumberAnimation { target: errHalo; property: "opacity"; to: 0.9; duration: 90 }
                                NumberAnimation { target: errHalo; property: "opacity"; to: 0.0; duration: 420 }
                            }
                        }

                        // Real input: always Normal echo, transparent text when masked
                        TextInput {
                            id: passField
                            anchors.fill: parent
                            anchors.leftMargin: M3.s24
                            anchors.rightMargin: 56
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            echoMode: TextInput.Normal
                            color: root.showPassword ? M3.m3OnSurface : "transparent"
                            selectedTextColor: "transparent"
                            selectionColor: "transparent"
                            cursorVisible: root.showPassword
                            selectByMouse: root.showPassword
                            font {
                                family: M3.fontFamily
                                pixelSize: 18
                                weight: Font.Medium
                                letterSpacing: root.showPassword ? 0 : 4
                            }
                            focus: true
                            text: root.passText
                            onTextChanged: if (text !== root.passText) root.passText = text
                            onAccepted: root.tryUnlock()
                            Keys.onEscapePressed: { root.passText = ""; text = "" }

                            Rectangle {
                                visible: !root.showPassword && passField.activeFocus
                                    && passField.text.length === 0
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: 22
                                radius: 1
                                color: M3.primary
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.0; duration: 500 }
                                    NumberAnimation { to: 1.0; duration: 500 }
                                }
                            }
                        }

                        // ===== Hidden-password shapes (random from M3 catalog) =====
                        Row {
                            id: dotsRow
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -14
                            spacing: 10
                            visible: !root.showPassword

                            Repeater {
                                model: passField.text.length

                                delegate: ExpressiveDot {
                                    required property int index

                                    readonly property bool newest:
                                        index === passField.text.length - 1

                                    readonly property int shapeSeed: {
                                        var h = (index + 1) * 2654435761
                                        h = (h ^ (h >>> 13)) >>> 0
                                        h = (h * 2246822519) >>> 0
                                        h = (h ^ (h >>> 11)) >>> 0
                                        return h
                                    }
                                    readonly property string pickedShape:
                                        root.dotCatalog[shapeSeed % root.dotCatalog.length]

                                    shape: pickedShape
                                    dotSize: newest ? 16 : 14
                                    roundness: 0.75
                                    spin: -Math.PI / 2

                                    dotColor: newest ? M3.primary : M3.m3OnSurfaceVariant
                                    Behavior on dotColor { ColorAnimation { duration: M3.durFast } }
                                    Behavior on dotSize {
                                        NumberAnimation { duration: M3.durMed; easing.type: Easing.OutCubic }
                                    }

                                    morph: 0.0
                                    NumberAnimation on morph {
                                        from: 0.0; to: 1.0
                                        duration: 340
                                        easing.type: Easing.OutCubic
                                    }

                                    scale: 0.0
                                    NumberAnimation on scale {
                                        from: 0.0; to: 1.0
                                        duration: 320
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.7
                                    }

                                    rotation: -18
                                    NumberAnimation on rotation {
                                        from: -18; to: 0
                                        duration: 360
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.4
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -14
                            visible: root.passText.length === 0 && !passField.activeFocus
                            text: "Enter password"
                            color: M3.m3OnSurfaceVariant
                            font {
                                family: M3.fontFamily
                                pixelSize: 15
                                weight: Font.Medium
                            }
                        }

                        // eye toggle
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44; height: 44
                            radius: M3.rFull
                            color: eyeMa.containsMouse
                                 ? M3.hoverOf(M3.tertiary)
                                 : (root.showPassword ? M3.tertiaryContainer : "transparent")
                            Behavior on color { ColorAnimation { duration: M3.durFast } }

                            Text {
                                anchors.centerIn: parent
                                text: root.showPassword ? "visibility_off" : "visibility"
                                color: M3.m3OnSurfaceVariant
                                font { family: "Material Symbols Rounded"; pixelSize: 20 }
                            }
                            MouseArea {
                                id: eyeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.showPassword = !root.showPassword
                                    passField.forceActiveFocus()
                                }
                            }
                        }
                    }

                    // ---- status chip ----
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: statusRow.implicitWidth + M3.s16
                        implicitHeight: 28
                        radius: M3.rFull
                        color: root.statusWorking
                             ? Qt.rgba(M3.primary.r, M3.primary.g, M3.primary.b, 0.14)
                             : root.statusError
                             ? M3.errorContainer
                             : Qt.rgba(M3.m3OnSurfaceVariant.r, M3.m3OnSurfaceVariant.g,
                                       M3.m3OnSurfaceVariant.b, 0.10)
                        Behavior on color { ColorAnimation { duration: M3.durMed } }

                        opacity: root.clamp01((card.reveal - 0.45) * 4)
                        transform: Translate {
                            y: (1 - root.clamp01((card.reveal - 0.45) * 4)) * 14
                        }

                        Row {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: M3.s8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.statusWorking ? "progress_activity"
                                    : root.statusError   ? "error"
                                    : "lock"
                                color: root.statusWorking ? M3.primary
                                     : root.statusError   ? M3.error
                                     : M3.m3OnSurfaceVariant
                                font { family: "Material Symbols Rounded"; pixelSize: 14 }

                                // spin the "progress_activity" icon while working
                                transformOrigin: Item.Center
                                SequentialAnimation on rotation {
                                    running: root.statusWorking
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0; to: 360; duration: 1400; easing.type: Easing.Linear }
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.statusWorking ? "Authenticating…"
                                    : root.statusError   ? "Wrong password · attempt " + root.errorCount
                                    : "Locked"
                                color: root.statusWorking ? M3.primary
                                     : root.statusError   ? M3.error
                                     : M3.m3OnSurfaceVariant
                                font: M3.labelMedium
                            }
                        }
                    }

                    // ---- power row ----
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: M3.s8

                        opacity: root.clamp01((card.reveal - 0.60) * 4)
                        transform: Translate {
                            y: (1 - root.clamp01((card.reveal - 0.60) * 4)) * 14
                        }

                        Repeater {
                            model: [
                                { glyph: "bedtime",            label: "Sleep",  cmd: ["systemctl", "suspend"],  tint: "secondary" },
                                { glyph: "restart_alt",        label: "Reboot", cmd: ["systemctl", "reboot"],   tint: "tertiary"  },
                                { glyph: "power_settings_new", label: "Off",    cmd: ["systemctl", "poweroff"], tint: "error"     }
                            ]
                            delegate: Rectangle {
                                id: powerBtn
                                required property var modelData

                                implicitWidth: pRow.implicitWidth + M3.s24
                                implicitHeight: 44
                                radius: M3.rFull

                                readonly property color _base:
                                    modelData.tint === "error"    ? M3.errorContainer
                                  : modelData.tint === "tertiary" ? M3.tertiaryContainer
                                  :                                 M3.secondaryContainer
                                readonly property color _fg:
                                    modelData.tint === "error" ? M3.error : M3.m3OnSecondaryContainer

                                color: pMa.pressed      ? M3.pressedOf(_base)
                                     : pMa.containsMouse ? M3.hoverOf(_base)
                                     : _base
                                Behavior on color { ColorAnimation { duration: M3.durFast } }

                                // press bounce
                                scale: pMa.pressed ? 0.94 : (pMa.containsMouse ? 1.03 : 1.0)
                                Behavior on scale {
                                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                }

                                Row {
                                    id: pRow
                                    anchors.centerIn: parent
                                    spacing: M3.s8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.glyph
                                        color: powerBtn._fg
                                        font { family: "Material Symbols Rounded"; pixelSize: 18 }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        color: powerBtn._fg
                                        font: M3.labelLarge
                                    }
                                }
                                MouseArea {
                                    id: pMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.powerExec = modelData.cmd
                                }
                            }
                        }
                    }
                }
            }

            // ============ SUCCESS FLASH ============
            Rectangle {
                id: successFlash
                anchors.fill: parent
                color: M3.primary
                opacity: 0
                z: 100
                SequentialAnimation {
                    id: successFlashAnim
                    NumberAnimation { target: successFlash; property: "opacity"; to: 0.35; duration: 120 }
                    NumberAnimation { target: successFlash; property: "opacity"; to: 0.0; duration: 480; easing.type: Easing.OutCubic }
                }
            }

            // ============ POWER CONFIRM DIALOG ============
            Rectangle {
                id: confirmPower
                anchors.fill: parent
                color: M3.scrim
                opacity: visible ? 0.7 : 0
                visible: root.powerExec.length > 0
                Behavior on opacity { NumberAnimation { duration: M3.durMed } }
                MouseArea { anchors.fill: parent }

                Rectangle {
                    anchors.centerIn: parent
                    width: 400
                    height: col2.implicitHeight + M3.s24 * 2
                    radius: 32
                    color: M3.surfaceContainerHigh
                    border.width: 1
                    border.color: M3.outlineVariant
                    scale: confirmPower.visible ? 1.0 : 0.9
                    Behavior on scale {
                        NumberAnimation {
                            duration: M3.durMed
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.1
                        }
                    }

                    Column {
                        id: col2
                        anchors {
                            left: parent.left; right: parent.right; top: parent.top
                            margins: M3.s24
                        }
                        spacing: M3.s24

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56; height: 56
                            radius: M3.rFull
                            color: M3.errorContainer

                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.06; duration: 1800; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.06; to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                color: M3.error
                                font { family: "Material Symbols Rounded"; pixelSize: 26 }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.powerExec.length === 0 ? ""
                                : "Really " + root.powerExec[root.powerExec.length - 1] + "?"
                            color: M3.m3OnSurface
                            font: M3.titleLarge
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: M3.s12

                            Rectangle {
                                width: 140; height: 44; radius: M3.rFull
                                color: yesMa.pressed      ? M3.pressedOf(M3.errorContainer)
                                     : yesMa.containsMouse ? M3.hoverOf(M3.errorContainer)
                                     : M3.errorContainer
                                Behavior on color { ColorAnimation { duration: M3.durFast } }
                                scale: yesMa.pressed ? 0.95 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Row {
                                    anchors.centerIn: parent
                                    spacing: M3.s8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "check"
                                        color: M3.error
                                        font { family: "Material Symbols Rounded"; pixelSize: 16 }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Yes"
                                        color: M3.error
                                        font: M3.labelLarge
                                    }
                                }
                                MouseArea {
                                    id: yesMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.runPower(root.powerExec)
                                        root.powerExec = []
                                    }
                                }
                            }

                            Rectangle {
                                width: 140; height: 44; radius: M3.rFull
                                color: noMa.pressed      ? M3.pressedOf(M3.primary)
                                     : noMa.containsMouse ? M3.hoverOf(M3.primary)
                                     : M3.primary
                                Behavior on color { ColorAnimation { duration: M3.durFast } }
                                scale: noMa.pressed ? 0.95 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                Row {
                                    anchors.centerIn: parent
                                    spacing: M3.s8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "close"
                                        color: M3.m3OnPrimary
                                        font { family: "Material Symbols Rounded"; pixelSize: 16 }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Cancel"
                                        color: M3.m3OnPrimary
                                        font: M3.labelLarge
                                    }
                                }
                                MouseArea {
                                    id: noMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.powerExec = []
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: quitTimer
        interval: 200
        onTriggered: Qt.quit()
    }

    Timer {
        interval: 2500
        onTriggered: {
            if (!lock.secure) {
                console.error("ilock: compositor did not confirm session lock " +
                              "(ext-session-lock-v1 unsupported?) — quitting")
                Qt.quit()
            }
        }
        Component.onCompleted: start()
    }

    IpcHandler {
        target: "ilock"
        function relock(): void { lock.locked = true }
        function quit(): void { Qt.quit() }
    }
}
