import QtQuick
import QtQuick.Effects
import Quickshell
import "root:/theme"
import "root:/settings"
import "material"

// LockNothing — сцена локскріну в дизайні "Nothing".
//   • розмите, трохи знебарвлене шпалерне тло (повільний Ken Burns + ледь помітний паралакс) під темною вуаллю
//   • великий dot-matrix годинник: цифри плавно «перегортаються», без миготіння
//   • пароль — капсула з 16 точок: літера запалює точку з «пульсом»; перевірка — хвиля; успіх — хвиля зліва направо;
//     помилка — червоний спалах + стрясання
//   • вхід у сцену поетапний: тло → годинник → капсула → кнопки
// Стан і дії беруться з LockScreen.qml (ctl): passText, tryUnlock(), statusWorking/Error, powerExec …
Item {
    id: scene

    required property var ctl

    readonly property color ink:  M3.m3OnSurface
    readonly property color dim:  M3.m3OnSurfaceVariant
    readonly property color line: M3.outline
    readonly property color red:  ThemeNothing.red
    readonly property int slots: 16
    readonly property real k: Math.max(0.75, height / 1080)
    readonly property string mono: M3.fontMono

    property bool errFlash: false
    property real sweep: -2          // хвиля перевірки
    property real succ: -1           // хвиля успіху
    property real intro: 0           // 0 → 1: хореографія появи
    property real parX: 0
    property real parY: 0
    property var now: new Date()

    function clamp01(v) { return v < 0 ? 0 : (v > 1 ? 1 : v) }
    function stage(from, span) { return clamp01((intro - from) / span) }   // локальний прогрес етапу появи
    function focusInput() { passField.forceActiveFocus() }

    Component.onCompleted: { focusInput(); introAnim.start() }

    NumberAnimation { id: introAnim; target: scene; property: "intro"; from: 0; to: 1; duration: 1500; easing.type: Easing.OutCubic }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: scene.now = new Date()
    }

    // ---------------------------------------------------------------- тло
    Rectangle { anchors.fill: parent; color: M3.surface }

    Item {
        id: wpLayer
        readonly property int overscan: 48
        width: scene.width + overscan * 2
        height: scene.height + overscan * 2
        x: -overscan - scene.parX * 14
        y: -overscan - scene.parY * 14
        transformOrigin: Item.Center
        opacity: wpFx.visible ? scene.stage(0.0, 0.6) : 0

        property real kb: 1.0
        SequentialAnimation on kb {
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 1.06; duration: 26000; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.06; to: 1.0; duration: 26000; easing.type: Easing.InOutSine }
        }
        scale: kb

        Image {
            id: wpImg
            anchors.fill: parent
            source: scene.ctl.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            id: wpFx
            anchors.fill: parent
            source: wpImg
            visible: wpImg.status === Image.Ready
            blurEnabled: true
            blur: 0.55
            blurMax: 48
            saturation: -0.55            // у дусі Nothing — майже монохромне
            brightness: -0.04
        }
    }

    // вуаль + м'яке затемнення зверху/знизу для читабельності
    Rectangle {
        anchors.fill: parent
        color: M3.surface
        opacity: wpFx.visible ? 0.58 : 1.0
        Behavior on opacity { NumberAnimation { duration: 700 } }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(M3.surface.r, M3.surface.g, M3.surface.b, 0.55) }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1.0;  color: Qt.rgba(M3.surface.r, M3.surface.g, M3.surface.b, 0.70) }
        }
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.06 * scene.stage(0.1, 0.5)
        readonly property color c: scene.ink
        onCChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = c
            const pitch = 28
            for (let y = pitch / 2; y < height; y += pitch)
                for (let x = pitch / 2; x < width; x += pitch)
                    ctx.fillRect(x, y, 2, 2)
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: scene.focusInput()
        onPositionChanged: mouse => {
            scene.parX = (mouse.x / width  - 0.5) * 2
            scene.parY = (mouse.y / height - 0.5) * 2
        }
        onExited: { scene.parX = 0; scene.parY = 0 }
    }
    Behavior on parX { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    Behavior on parY { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    // ---------------------------------------------------------------- шапка
    Row {
        anchors { left: parent.left; top: parent.top; leftMargin: 40; topMargin: 36 }
        spacing: 10
        opacity: scene.stage(0.15, 0.4)
        Rectangle {
            width: 7; height: 7; radius: 3.5
            anchors.verticalCenter: parent.verticalCenter
            color: scene.ctl.statusError || scene.errFlash ? scene.red : scene.ink
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Lang.t("lock.locked").toUpperCase()
            color: scene.dim
            font { family: scene.mono; pixelSize: 12; letterSpacing: 3 }
        }
    }

    Text {
        anchors { right: parent.right; top: parent.top; rightMargin: 40; topMargin: 36 }
        opacity: scene.stage(0.15, 0.4)
        text: (Quickshell.env("USER") || "").toUpperCase()
        color: scene.dim
        font { family: scene.mono; pixelSize: 12; letterSpacing: 3 }
    }

    // ---------------------------------------------------------------- годинник
    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -scene.height * 0.11 + (1 - scene.stage(0.05, 0.5)) * 26
        opacity: scene.stage(0.05, 0.5)
        spacing: Math.round(20 * scene.k)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            readonly property int px: Math.round(scene.height * 0.22)
            readonly property string hh: Qt.formatDateTime(scene.now, "hh")
            readonly property string mm: Qt.formatDateTime(scene.now, "mm")

            RollDigit { value: parent.hh.charAt(0); px: parent.px; tint: scene.ink; fam: M3.clockFamily }
            RollDigit { value: parent.hh.charAt(1); px: parent.px; tint: scene.ink; fam: M3.clockFamily }
            Text {
                text: ":"
                color: scene.ink
                opacity: 0.45
                font { family: M3.clockFamily; pixelSize: parent.px }
            }
            RollDigit { value: parent.mm.charAt(0); px: parent.px; tint: scene.ink; fam: M3.clockFamily }
            RollDigit { value: parent.mm.charAt(1); px: parent.px; tint: scene.ink; fam: M3.clockFamily }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(scene.now, "dddd · d MMMM").toUpperCase()
            color: scene.dim
            font { family: scene.mono; pixelSize: Math.round(15 * Math.max(1, scene.k)); letterSpacing: 4 }
        }

        // 60 точок-секунд: пройдені — напівяскраві, поточна — червона й трохи більша
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Repeater {
                model: 60
                delegate: Rectangle {
                    id: tick
                    required property int index
                    readonly property int sec: scene.now.getSeconds()
                    readonly property bool cur: index === sec
                    width: 4; height: 4; radius: 2
                    color: cur ? scene.red : scene.ink
                    opacity: cur ? 1.0 : (index < sec ? 0.5 : ThemeNothing.dotOpacityOff)
                    scale: cur ? 1.7 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 260 } }
                    Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
                    Behavior on color   { ColorAnimation { duration: 200 } }
                }
            }
        }
    }

    // ---------------------------------------------------------------- пароль + живлення
    Column {
        id: bottomCol
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(56 * Math.max(1, scene.k))
        spacing: 20

        // підказка / статус
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: scene.stage(0.35, 0.4)
            text: (scene.ctl.statusWorking ? Lang.t("lock.auth")
                 : scene.ctl.statusError   ? Lang.t("lock.wrong").replace("{n}", scene.ctl.errorCount)
                 : Lang.t("lock.enter")).toUpperCase()
            color: scene.ctl.statusError ? scene.red : scene.dim
            font { family: scene.mono; pixelSize: 12; letterSpacing: 4 }
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // відкритий пароль (режим «показати»)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            height: scene.ctl.showPassword ? 26 : 0
            visible: height > 1
            clip: true
            text: scene.ctl.passText
            color: scene.ink
            verticalAlignment: Text.AlignVCenter
            font { family: scene.mono; pixelSize: 20; letterSpacing: 4 }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        // капсула з 16 точок-слотів
        Rectangle {
            id: capsule
            anchors.horizontalCenter: parent.horizontalCenter
            width: slotRow.implicitWidth + 52
            height: 56
            radius: 28
            color: Qt.rgba(M3.surface.r, M3.surface.g, M3.surface.b, 0.40)
            border.width: 1
            border.color: scene.errFlash ? scene.red
                        : passField.activeFocus ? Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.55)
                        : scene.line
            Behavior on border.color { ColorAnimation { duration: 220 } }

            opacity: scene.stage(0.4, 0.4)
            scale: 0.92 + 0.08 * scene.stage(0.4, 0.5)
            transform: Translate { id: shakeShift; x: 0 }

            Row {
                id: slotRow
                anchors.centerIn: parent
                spacing: 14

                Repeater {
                    model: scene.slots
                    delegate: Item {
                        id: slot
                        required property int index
                        readonly property bool lit: index < scene.ctl.passText.length
                        readonly property bool newest: index === scene.ctl.passText.length - 1
                        readonly property bool wave: scene.ctl.statusWorking && Math.abs(index - scene.sweep) < 1.6
                        readonly property bool ok: index <= scene.succ
                        readonly property real appear: scene.clamp01((scene.intro - 0.5 - index * 0.012) * 7)

                        width: 12; height: 12

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: scene.errFlash ? scene.red : scene.ink
                            opacity: (scene.errFlash || slot.lit || slot.wave || slot.ok)
                                     ? 1.0 : ThemeNothing.dotOpacityOff
                            scale: (slot.newest ? 1.35 : (slot.lit || slot.ok ? 1.0 : 0.78)) * slot.appear
                            Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                            Behavior on color   { ColorAnimation  { duration: 160 } }
                        }

                        // кільце-«пульс» при введенні символу
                        Rectangle {
                            id: ripple
                            anchors.centerIn: parent
                            width: 12; height: 12; radius: 6
                            color: "transparent"
                            border.width: 1
                            border.color: scene.ink
                            opacity: 0
                        }
                        ParallelAnimation {
                            id: rippleAnim
                            NumberAnimation { target: ripple; property: "scale"; from: 1.0; to: 2.6; duration: 520; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ripple; property: "opacity"; from: 0.55; to: 0.0; duration: 520; easing.type: Easing.OutCubic }
                        }
                        onLitChanged: if (lit) rippleAnim.restart()
                    }
                }
            }
        }

        // перемикач «показати / сховати»
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: showLabel.implicitWidth + 28
            height: 26
            radius: 13
            opacity: scene.stage(0.5, 0.4)
            color: showMa.containsMouse ? Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.10) : "transparent"
            border.width: 1
            border.color: scene.line
            Behavior on color { ColorAnimation { duration: 140 } }
            Text {
                id: showLabel
                anchors.centerIn: parent
                text: (scene.ctl.showPassword ? Lang.t("lock.hide") : Lang.t("lock.show")).toUpperCase()
                color: scene.dim
                font { family: scene.mono; pixelSize: 10; letterSpacing: 3 }
            }
            MouseArea {
                id: showMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { scene.ctl.showPassword = !scene.ctl.showPassword; scene.focusInput() }
            }
        }

        // живлення
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 30
            topPadding: 8

            Repeater {
                model: [
                    { glyph: "bedtime",            key: "lock.sleep",  cmd: ["systemctl", "suspend"],  danger: false },
                    { glyph: "restart_alt",        key: "lock.reboot", cmd: ["systemctl", "reboot"],   danger: false },
                    { glyph: "power_settings_new", key: "lock.off",    cmd: ["systemctl", "poweroff"], danger: true  }
                ]
                delegate: Column {
                    id: pb
                    required property var modelData
                    required property int index
                    spacing: 8
                    opacity: scene.stage(0.58 + index * 0.06, 0.36)
                    transform: Translate { y: (1 - scene.stage(0.58 + pb.index * 0.06, 0.36)) * 14 }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 46; height: 46; radius: 23
                        color: pMa.pressed ? Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.18)
                             : pMa.containsMouse ? Qt.rgba(scene.ink.r, scene.ink.g, scene.ink.b, 0.10)
                             : Qt.rgba(M3.surface.r, M3.surface.g, M3.surface.b, 0.40)
                        border.width: 1
                        border.color: pMa.containsMouse && pb.modelData.danger ? scene.red : scene.line
                        scale: pMa.pressed ? 0.92 : (pMa.containsMouse ? 1.07 : 1.0)
                        Behavior on color        { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale        { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: pb.modelData.glyph
                            color: pMa.containsMouse && pb.modelData.danger ? scene.red : scene.ink
                            font { family: "Material Symbols Rounded"; pixelSize: 20 }
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        MouseArea {
                            id: pMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: scene.ctl.powerExec = pb.modelData.cmd
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Lang.t(pb.modelData.key).toUpperCase()
                        color: scene.dim
                        font { family: scene.mono; pixelSize: 10; letterSpacing: 3 }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------- вхід (невидимий, лише фокус/ввід)
    TextInput {
        id: passField
        width: 1; height: 1
        opacity: 0
        focus: true
        echoMode: TextInput.Normal
        text: scene.ctl.passText
        onTextChanged: if (text !== scene.ctl.passText) scene.ctl.passText = text
        onAccepted: {
            if (scene.ctl.authenticating || text.length === 0) return
            scene.ctl.tryUnlock()
            text = ""                                   // очистити поле, щоб старий пароль не лишався в точках
        }
        Keys.onEscapePressed: { scene.ctl.passText = ""; text = "" }
    }

    // ---------------------------------------------------------------- анімації подій
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeShift; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeShift; property: "x"; to:  10; duration: 70; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeShift; property: "x"; to:  -6; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeShift; property: "x"; to:   3; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeShift; property: "x"; to:   0; duration: 70; easing.type: Easing.OutQuad }
    }
    Timer { id: errTimer; interval: 700; onTriggered: scene.errFlash = false }

    NumberAnimation { id: succAnim; target: scene; property: "succ"; from: -1; to: scene.slots + 3; duration: 520; easing.type: Easing.InOutQuad }

    Connections {
        target: scene.ctl
        function onShakeTickChanged() {
            scene.errFlash = true
            errTimer.restart()
            shakeAnim.restart()
        }
        function onSuccessTickChanged() { succAnim.restart() }
    }

    // «хвиля» під час перевірки паролю
    NumberAnimation {
        target: scene
        property: "sweep"
        from: -2; to: scene.slots + 1
        duration: 1000
        loops: Animation.Infinite
        running: scene.ctl.statusWorking
    }
}
