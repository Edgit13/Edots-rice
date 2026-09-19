import "root:/"
import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// WifiSurface.qml — Material 3 (Крок: Wifi). Логика — WifiService (без змін);
// лоадер — LoadingIndicator (M3 Expressive) при скануванні/підключенні.
// ==========================================================================

Item {
    id: root

    property string passwordInput: ""

    Component.onCompleted: WifiService.scan()

    function signalIcon(signalPct) {
        const s = signalPct / 100
        if (s >= 0.75) return "\ue1ba"
        if (s >= 0.50) return "\uebe1"
        if (s >= 0.25) return "\uebd6"
        return "\uebe4"
    }

    // ---- M3 мережевий рядок ----
    component NetworkRow: Rectangle {
        id: row
        property string ssid: ""
        property int signalPct: 0
        property bool secured: false
        property bool inUse: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: Md.rM
        color: row.inUse ? Md.primaryContainer
            : (rowMa.containsMouse ? Md.hoverOf(Md.surfaceContainerHigh) : Md.surfaceContainerHigh)
        Behavior on color { ColorAnimation { duration: Md.durFast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: root.signalIcon(row.signalPct)
                color: row.inUse ? Md.primary : Md.onSurfaceVariant
                font { family: "Material Symbols Rounded"; pixelSize: 16 }
            }
            Text {
                Layout.fillWidth: true
                text: row.ssid
                color: row.inUse ? Md.onPrimaryContainer : Md.onSurface
                font { family: "SF Pro Display"; pixelSize: 12; weight: row.inUse ? 600 : 400 }
                elide: Text.ElideRight
            }
            Text {
                visible: row.secured
                text: "\ue899"
                color: Md.onSurfaceVariant
                font { family: "Material Symbols Rounded"; pixelSize: 13 }
            }
            Text {
                text: row.signalPct + "%"
                color: Md.onSurfaceVariant
                font { family: "SF Mono"; pixelSize: 11 }
                Layout.preferredWidth: 32
            }
        }

        MouseArea {
            id: rowMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    // ---- головний список ----
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: WifiService.connectionState !== "passwordRequired" && WifiService.connectionState !== "connecting"

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "\ue63e"
                color: Md.primary
                font { family: "Material Symbols Rounded"; pixelSize: 18 }
            }
            Text {
                Layout.fillWidth: true
                text: "Wi-Fi"
                color: Md.onSurface
                font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
            }

            // лоадер при скануванні (M3 Expressive), інакше — рефреш
            LoadingIndicator {
                visible: WifiService.scanning
                size: 22
            }
            Text {
                visible: !WifiService.scanning
                text: "\ue5d5"
                color: refreshHover.hovered ? Md.primary : Md.onSurfaceVariant
                font { family: "Material Symbols Rounded"; pixelSize: 17 }
                HoverHandler { id: refreshHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.scan()
                }
            }

            // M3 switch Wi-Fi on/off
            Rectangle {
                width: 52
                height: 32
                radius: 16
                color: Networking.wifiEnabled ? Md.primary : "transparent"
                border.width: Networking.wifiEnabled ? 0 : 2
                border.color: Md.outline
                Rectangle {
                    width: Networking.wifiEnabled ? 24 : 16
                    height: width
                    radius: width / 2
                    x: Networking.wifiEnabled ? parent.width - width - 4 : 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: Networking.wifiEnabled ? Md.onPrimary : Md.outline
                    Behavior on x { NumberAnimation { duration: Md.durMed; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: Md.durFast } }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.toggleWifi()
                }
            }
        }

        // поточне підключення
        RowLayout {
            Layout.fillWidth: true
            visible: WifiService.currentNetwork !== null
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: WifiService.currentNetwork ? ("Підключено: " + WifiService.currentNetwork.ssid) : ""
                color: Md.primary
                font { family: "SF Pro Display"; pixelSize: 11 }
                elide: Text.ElideRight
            }
            Text {
                text: "\ue16f"
                color: disconnectHover.hovered ? Md.error : Md.onSurfaceVariant
                font { family: "Material Symbols Rounded"; pixelSize: 15 }
                HoverHandler { id: disconnectHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.disconnectCurrent()
                }
            }
        }

        // помилка
        RowLayout {
            Layout.fillWidth: true
            visible: WifiService.connectionState === "failed"
            spacing: 6
            Text {
                text: "\uf8b6"
                color: Md.error
                font { family: "Material Symbols Rounded"; pixelSize: 14 }
            }
            Text {
                Layout.fillWidth: true
                text: WifiService.connectionError + " (" + WifiService.pendingSsid + ")"
                color: Md.error
                font { family: "SF Pro Display"; pixelSize: 10 }
                elide: Text.ElideRight
            }
            Text {
                text: "Повторити"
                color: Md.primary
                font { family: "SF Pro Display"; pixelSize: 10; underline: true }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WifiService.requestConnect(WifiService.pendingSsid)
                }
            }
        }

        // список мереж
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: networksCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: networksCol
                width: parent.width
                spacing: 6

                Text {
                    visible: !Networking.wifiEnabled
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    text: "Увімкни Wi-Fi, щоб побачити мережі"
                    color: Md.onSurfaceVariant
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }

                Text {
                    visible: Networking.wifiEnabled && !WifiService.scanning && WifiService.networks.length === 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    text: "Мереж не знайдено"
                    color: Md.onSurfaceVariant
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }

                Repeater {
                    model: Networking.wifiEnabled ? WifiService.networks : []
                    delegate: NetworkRow {
                        required property var modelData
                        ssid: modelData.ssid
                        signalPct: modelData.signal
                        secured: modelData.secured
                        inUse: modelData.inUse
                        onClicked: WifiService.requestConnect(modelData.ssid)
                    }
                }
            }
        }
    }

    // ---- ввід пароля / підключення ----
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        visible: WifiService.connectionState === "passwordRequired" || WifiService.connectionState === "connecting"

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "\ue5c4"
                color: backHover.hovered ? Md.primary : Md.onSurfaceVariant
                font { family: "Material Symbols Rounded"; pixelSize: 16 }
                HoverHandler { id: backHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    enabled: WifiService.connectionState === "passwordRequired"
                    onClicked: WifiService.cancelPassword()
                }
            }
            Text {
                Layout.fillWidth: true
                text: WifiService.pendingSsid
                color: Md.onSurface
                font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
                elide: Text.ElideRight
            }
        }

        // лоадер при підключенні (M3 Expressive)
        RowLayout {
            visible: WifiService.connectionState === "connecting"
            spacing: 10
            LoadingIndicator { size: 26 }
            Text {
                text: "Підключення..."
                color: Md.onSurfaceVariant
                font { family: "SF Pro Display"; pixelSize: 12 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            visible: WifiService.connectionState === "passwordRequired"
            radius: Md.rS
            color: Md.surfaceContainerLow
            border.width: pwInput.activeFocus ? 2 : 1
            border.color: pwInput.activeFocus ? Md.primary : Md.outlineVariant

            TextInput {
                id: pwInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Md.onSurface
                font { family: "SF Pro Display"; pixelSize: 12 }
                echoMode: TextInput.Password
                focus: WifiService.connectionState === "passwordRequired"
                text: root.passwordInput
                onTextChanged: root.passwordInput = text

                Keys.onReturnPressed: root.submitPw()
                Keys.onEnterPressed: root.submitPw()
            }
        }

        Text {
            visible: WifiService.connectionState === "passwordRequired"
            text: "Enter \u2014 підключитись"
            color: Md.onSurfaceVariant
            font { family: "SF Pro Display"; pixelSize: 9; italic: true }
        }
    }

    function submitPw() {
        if (pwInput.text.length > 0) {
            WifiService.connectTo(WifiService.pendingSsid, pwInput.text)
            root.passwordInput = ""
        }
    }
}
