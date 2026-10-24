import "root:/theme"
import "root:/services"
import "root:/settings"
import "root:/modules/common"
import QtQuick

// RecordModule — у барі лише під час запису: червона крапка, що пульсує, і таймер 00:12.
// При наведенні крапка стає квадратом «стоп»; клік зупиняє запис.
BarModule {
    id: root

    readonly property bool active: RecordService.recording

    shown: active
    animate: true
    contentW: row.implicitWidth + Theme.space.md * 2
    contentH: col.implicitHeight + Theme.space.sm * 2

    component RecDot: Rectangle {
        id: dot
        property bool hovered: false
        property bool pulsing: false                       // inline-компонент не бачить id зовнішнього файлу — параметри через властивості
        implicitWidth: Theme.components.dp(10)
        implicitHeight: implicitWidth
        radius: hovered ? Theme.components.dp(2) : width / 2
        color: Theme.color.error
        Behavior on radius { MotionAnimation { role: "morph" } }

        SequentialAnimation on opacity {
            running: dot.pulsing
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
        }
        onHoveredChanged: if (hovered) opacity = 1
    }

    BarButton {
        id: btn
        anchors.fill: parent
        accent: true
        accentColor: Theme.color.errorContainer
        stateColor: Theme.color.fgErrorContainer
        onClicked: RecordService.stop()

        Row {
            id: row
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.sm
            RecDot { anchors.verticalCenter: parent.verticalCenter; hovered: btn.hovered; pulsing: root.active && !btn.hovered }
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: RecordService.elapsedText
                style: Theme.type.monoMedium
                emphasized: true
                color: Theme.color.fgErrorContainer
            }
        }

        Column {
            id: col
            visible: root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xxs
            RecDot { anchors.horizontalCenter: parent.horizontalCenter; hovered: btn.hovered; pulsing: root.active && !btn.hovered }
            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: RecordService.elapsedText.split(":").slice(-2).join("\n")
                style: Theme.type.labelSmall
                color: Theme.color.fgErrorContainer
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
