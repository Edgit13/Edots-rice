pragma ComponentBehavior: Bound
import "root:/theme"
import "."
import "material"
import "controls"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// SettingsApp — M3 Expressive: навігація зі слайд-індикатором, search bar, секції як connected list.
Item {
    id: app
    property int currentIndex: 0

    readonly property real navItemH: Theme.components.buttonM
    readonly property real navGap: Theme.space.xxs

    onCurrentIndexChanged: {
        pageIn.restart()
        ensureNavVisible(currentIndex)
    }

    function ensureNavVisible(idx: int): void {
        if (!navFlick) return
        const itemY = idx * (app.navItemH + app.navGap)
        const itemH = app.navItemH
        if (itemY < navFlick.contentY) {
            navFlick.contentY = Math.max(0, itemY)
        } else if (itemY + itemH > navFlick.contentY + navFlick.height) {
            navFlick.contentY = Math.min(Math.max(0, navFlick.contentHeight - navFlick.height), itemY + itemH - navFlick.height)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ───────── navigation ─────────
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: Theme.components.dp(236)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.lg
                spacing: 0

                ThemedText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space.md
                    Layout.bottomMargin: Theme.space.lg
                    text: Lang.t("settings.title")
                    style: Theme.type.headlineSmall
                }

                Flickable {
                    id: navFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: navColWrap.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        target: navFlick
                        orientation: Qt.Vertical
                        onWheel: event => {
                            const step = (app.navItemH + app.navGap) * 2
                            const delta = event.angleDelta.y > 0 ? -step : step
                            navFlick.contentY = Math.max(0, Math.min(navFlick.contentHeight - navFlick.height, navFlick.contentY + delta))
                        }
                    }

                    Item {
                        id: navColWrap
                        width: navFlick.width
                        implicitHeight: navCol.implicitHeight + Theme.space.sm

                        // індикатор активної сторінки: їде між пунктами
                        Rectangle {
                            width: parent.width
                            height: app.navItemH
                            radius: Theme.shape.navItem
                            color: Theme.color.secondaryContainer
                            y: app.currentIndex * (app.navItemH + app.navGap)
                            Behavior on y { MotionAnimation { role: "move" } }
                        }

                        ColumnLayout {
                            id: navCol
                            width: parent.width
                            spacing: app.navGap

                            Repeater {
                                model: Schema.pages
                                Item {
                                    id: navItem
                                    required property var modelData
                                    required property int index
                                    readonly property bool active: app.currentIndex === index

                                    Layout.fillWidth: true
                                    implicitHeight: app.navItemH

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.shape.navItem
                                        color: Theme.color.fgSurface
                                        opacity: navMa.pressed ? Theme.components.statePressed
                                               : (navMa.containsMouse && !navItem.active) ? Theme.components.stateHover : 0
                                        Behavior on opacity { MotionAnimation { role: "hover" } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.space.lg
                                        anchors.rightMargin: Theme.space.lg
                                        spacing: Theme.space.md
                                        Text {
                                            text: navItem.modelData.icon
                                            color: navItem.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                                            font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                                            Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                        }
                                        ThemedText {
                                            Layout.fillWidth: true
                                            text: Lang.t(navItem.modelData.name)
                                            style: Theme.type.labelLarge
                                            emphasized: navItem.active
                                            color: navItem.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurface
                                            Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                        }
                                    }

                                    MouseArea {
                                        id: navMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: app.currentIndex = navItem.index
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ───────── content ─────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // search bar
            Rectangle {
                id: searchBar
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.lg
                Layout.leftMargin: Theme.space.lg
                Layout.rightMargin: Theme.space.lg
                Layout.bottomMargin: Theme.space.sm
                implicitHeight: Theme.components.dp(52)
                radius: Theme.shape.radius("full", height)
                color: Theme.color.surfaceContainerHigh
                border.width: search.activeFocus ? Theme.components.dp(2) : 0
                border.color: Theme.color.primary
                Behavior on border.color { MotionColorAnimation { role: "hover" } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.lg
                    anchors.rightMargin: Theme.space.sm
                    spacing: Theme.space.md

                    Text {
                        text: "search"
                        color: Theme.color.fgSurfaceVariant
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.color.fgSurface
                        font.family: Theme.type.bodyLarge.family
                        font.pixelSize: Theme.type.bodyLarge.size
                        selectByMouse: true
                        clip: true
                        onTextChanged: SettingsSearch.query = text
                        Keys.onEscapePressed: { text = ""; SettingsSearch.clear() }
                        ThemedText {
                            anchors.fill: parent
                            visible: search.text.length === 0
                            text: Lang.t("search.placeholder")
                            style: Theme.type.bodyLarge
                            color: Theme.color.fgSurfaceVariant
                        }
                    }
                    MaterialIconButton {
                        icon: "close"
                        visible: search.text.length > 0
                        onClicked: { search.text = ""; SettingsSearch.clear() }
                    }
                }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: pageCol.implicitHeight + Theme.space.xl * 2
                boundsBehavior: Flickable.StopAtBounds

                ParallelAnimation {
                    id: pageIn
                    MotionAnimation { target: pageCol; property: "opacity"; from: 0; to: 1; role: "enter" }
                    MotionAnimation { target: pageCol; property: "y"; from: Theme.space.xl; to: Theme.space.sm; role: "enter" }
                }

                ColumnLayout {
                    id: pageCol
                    width: flick.width - Theme.space.lg * 2
                    x: Theme.space.lg
                    y: Theme.space.sm
                    spacing: Theme.space.md

                    Repeater {
                        model: Settings.sectionsForPage(app.currentIndex)

                        ColumnLayout {
                            id: sectionWrap
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Theme.space.sm

                            ThemedText {
                                Layout.fillWidth: true
                                Layout.topMargin: Theme.space.md
                                Layout.leftMargin: Theme.space.md
                                text: Lang.t(sectionWrap.modelData.label).toUpperCase()
                                style: Theme.type.labelMedium
                                emphasized: true
                                color: Theme.color.primary
                                font.letterSpacing: 1.2 * Theme.space.k
                            }

                            // connected list: кожен рядок — окрема плитка, заокруглені лише краї групи
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space.listGap

                                Repeater {
                                    id: rows
                                    model: sectionWrap.modelData.fields

                                    Rectangle {
                                        id: rowBox
                                        required property var modelData
                                        required property int index

                                        function vis(i) {
                                            const f = sectionWrap.modelData.fields[i]
                                            return !!f && SettingsSearch.matches(Lang.searchText(f.cat, f.key, f.field))
                                        }
                                        readonly property bool shown: vis(index)
                                        readonly property bool isFirst: {
                                            for (let j = 0; j < index; j++) if (vis(j)) return false
                                            return true
                                        }
                                        readonly property bool isLast: {
                                            const n = sectionWrap.modelData.fields.length
                                            for (let j = index + 1; j < n; j++) if (vis(j)) return false
                                            return true
                                        }
                                        readonly property real big: Theme.shape.cardLarge
                                        readonly property real small: Theme.shape.listInner

                                        Layout.fillWidth: true
                                        visible: shown
                                        implicitHeight: sr.implicitHeight + Theme.space.md * 2
                                        color: Theme.color.surfaceContainer

                                        topLeftRadius: isFirst ? big : small
                                        topRightRadius: isFirst ? big : small
                                        bottomLeftRadius: isLast ? big : small
                                        bottomRightRadius: isLast ? big : small
                                        Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
                                        Behavior on topRightRadius { MotionAnimation { role: "morph" } }
                                        Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
                                        Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }

                                        SchemaRow {
                                            id: sr
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: Theme.space.lg
                                                rightMargin: Theme.space.lg
                                            }
                                            cat: rowBox.modelData.cat
                                            key: rowBox.modelData.key
                                            field: rowBox.modelData.field
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ───────── Wallpapers color categorization ─────────
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: visible ? Math.max(520, flick.height - Theme.space.xl * 2) : 0
                        visible: app.currentIndex === Schema.pages.length - 2
                        PageWallpapers { anchors.fill: parent }
                    }

                    // ───────── About ─────────
                    ColumnLayout {
                        id: aboutPage
                        Layout.fillWidth: true
                        visible: app.currentIndex === Schema.pages.length - 1
                        spacing: Theme.space.lg

                        ThemedText {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space.md
                            Layout.leftMargin: Theme.space.md
                            text: Lang.t("page.about").toUpperCase()
                            style: Theme.type.labelMedium
                            emphasized: true
                            color: Theme.color.primary
                            font.letterSpacing: 1.2 * Theme.space.k
                        }

                        // ── Hero Banner with dynamic gradient & floating ambient shapes ──
                        Rectangle {
                            id: heroCard
                            Layout.fillWidth: true
                            implicitHeight: heroCol.implicitHeight + Theme.space.xl * 2
                            radius: Theme.shape.cardLarge
                            color: Theme.color.surfaceContainer
                            border.width: 1
                            border.color: heroMa.containsMouse ? Theme.alpha(Theme.color.primary, 0.45) : Theme.color.outlineVariant
                            clip: true

                            Behavior on border.color { MotionColorAnimation { role: "hover" } }

                            // Animated expressive gradient overlay (breathing effect)
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Theme.alpha(Theme.color.primary, 0.16) }
                                    GradientStop { position: 0.5; color: Theme.alpha(Theme.color.secondary, 0.09) }
                                    GradientStop { position: 1.0; color: Theme.alpha(Theme.color.tertiary, 0.14) }
                                }
                                opacity: heroBreathAnim.glow
                            }

                            QtObject {
                                id: heroBreathAnim
                                property real glow: 0.7
                                SequentialAnimation on glow {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.5; to: 1.0; duration: 3600; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 1.0; to: 0.5; duration: 3600; easing.type: Easing.InOutSine }
                                }
                            }

                            // Floating ambient animated M3 shapes
                            Item {
                                anchors.fill: parent
                                clip: true

                                Item {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.components.dp(40)
                                    anchors.top: parent.top
                                    anchors.topMargin: Theme.components.dp(16)
                                    width: shape1.width
                                    height: shape1.height

                                    ExpressiveDot {
                                        id: shape1
                                        dotSize: Theme.components.dp(64)
                                        shape: "cookie"
                                        dotColor: Theme.color.primary
                                        opacity: 0.09
                                        y: floatY1.val

                                        SequentialAnimation on rotation {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 0; to: 360; duration: 24000; easing.type: Easing.Linear }
                                        }
                                    }
                                    QtObject {
                                        id: floatY1
                                        property real val: 0
                                        SequentialAnimation on val {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: -8; to: 10; duration: 3200; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 10; to: -8; duration: 3200; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }

                                Item {
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.components.dp(120)
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.components.dp(20)
                                    width: shape2.width
                                    height: shape2.height

                                    ExpressiveDot {
                                        id: shape2
                                        dotSize: Theme.components.dp(48)
                                        shape: "sunny"
                                        dotColor: Theme.color.tertiary
                                        opacity: 0.08
                                        x: floatX2.val
                                        y: floatY2.val

                                        SequentialAnimation on rotation {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 360; to: 0; duration: 18000; easing.type: Easing.Linear }
                                        }
                                    }
                                    QtObject {
                                        id: floatX2
                                        property real val: 0
                                        SequentialAnimation on val {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: -10; to: 10; duration: 4000; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 10; to: -10; duration: 4000; easing.type: Easing.InOutSine }
                                        }
                                    }
                                    QtObject {
                                        id: floatY2
                                        property real val: 0
                                        SequentialAnimation on val {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 6; to: -6; duration: 3400; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: -6; to: 6; duration: 3400; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }

                                Item {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.components.dp(260)
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Theme.components.dp(16)
                                    width: shape3.width
                                    height: shape3.height

                                    ExpressiveDot {
                                        id: shape3
                                        dotSize: Theme.components.dp(36)
                                        shape: "clover"
                                        dotColor: Theme.color.secondary
                                        opacity: 0.07
                                        y: floatY3.val

                                        SequentialAnimation on rotation {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 0; to: 360; duration: 20000; easing.type: Easing.Linear }
                                        }
                                    }
                                    QtObject {
                                        id: floatY3
                                        property real val: 0
                                        SequentialAnimation on val {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: -5; to: 8; duration: 2800; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 8; to: -5; duration: 2800; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: heroMa
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            ColumnLayout {
                                id: heroCol
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Theme.space.xl
                                }
                                spacing: Theme.space.md

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.space.lg

                                    // Glowing App Icon
                                    Item {
                                        implicitWidth: Theme.components.dp(64)
                                        implicitHeight: Theme.components.dp(64)

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width + Theme.components.dp(10)
                                            height: parent.height + Theme.components.dp(10)
                                            radius: Theme.shape.radius("xl", height)
                                            color: "transparent"
                                            border.width: Theme.components.dp(2)
                                            border.color: Theme.alpha(Theme.color.primary, 0.45)
                                            scale: iconHoverMa.containsMouse ? 1.08 : 1.0
                                            Behavior on scale { MotionAnimation { role: "morph" } }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.shape.radius("xl", height)
                                            color: Theme.color.primaryContainer
                                            Behavior on radius { MotionAnimation { role: "morph" } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "auto_awesome"
                                                color: Theme.color.fgPrimaryContainer
                                                font { family: Theme.type.icons; pixelSize: Theme.components.dp(32) }
                                                rotation: iconHoverMa.containsMouse ? 24 : 0
                                                scale: iconHoverMa.containsMouse ? 1.15 : 1.0
                                                Behavior on rotation { MotionAnimation { role: "morph" } }
                                                Behavior on scale { MotionAnimation { role: "morph" } }
                                            }

                                            MouseArea {
                                                id: iconHoverMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.space.xs

                                        RowLayout {
                                            spacing: Theme.space.sm

                                            ThemedText {
                                                text: Lang.t("about.title")
                                                style: Theme.type.headlineSmall
                                                emphasized: true
                                            }

                                            Rectangle {
                                                radius: Theme.shape.radius("full", height)
                                                color: Theme.color.primary
                                                implicitHeight: Theme.components.dp(22)
                                                implicitWidth: b1Text.implicitWidth + Theme.space.md * 2

                                                ThemedText {
                                                    id: b1Text
                                                    anchors.centerIn: parent
                                                    text: "v2.0"
                                                    style: Theme.type.labelSmall
                                                    emphasized: true
                                                    color: Theme.color.fgPrimary
                                                }
                                            }

                                            Rectangle {
                                                radius: Theme.shape.radius("full", height)
                                                color: Theme.color.secondaryContainer
                                                implicitHeight: Theme.components.dp(22)
                                                implicitWidth: b2Text.implicitWidth + Theme.space.md * 2

                                                ThemedText {
                                                    id: b2Text
                                                    anchors.centerIn: parent
                                                    text: Lang.t("about.badge")
                                                    style: Theme.type.labelSmall
                                                    emphasized: true
                                                    color: Theme.color.fgSecondaryContainer
                                                }
                                            }

                                            Rectangle {
                                                radius: Theme.shape.radius("full", height)
                                                color: Theme.color.tertiaryContainer
                                                implicitHeight: Theme.components.dp(22)
                                                implicitWidth: b3Text.implicitWidth + Theme.space.md * 2

                                                ThemedText {
                                                    id: b3Text
                                                    anchors.centerIn: parent
                                                    text: "MangoWC"
                                                    style: Theme.type.labelSmall
                                                    emphasized: true
                                                    color: Theme.color.fgTertiaryContainer
                                                }
                                            }
                                        }

                                        ThemedText {
                                            text: Lang.t("about.author")
                                            style: Theme.type.labelMedium
                                            color: Theme.color.primary
                                            emphasized: true
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: descText.implicitHeight + Theme.space.md * 2
                                    radius: Theme.shape.card
                                    color: Theme.alpha(Theme.color.surfaceContainerLowest, 0.45)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.color.outlineVariant, 0.6)

                                    ThemedText {
                                        id: descText
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: Theme.space.md
                                            rightMargin: Theme.space.md
                                        }
                                        text: Lang.t("about.body")
                                        style: Theme.type.bodyMedium
                                        color: Theme.color.fgSurfaceVariant
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }

                        // ── Links & Community ──
                        ThemedText {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space.md
                            Layout.leftMargin: Theme.space.md
                            text: Lang.t("about.links").toUpperCase()
                            style: Theme.type.labelMedium
                            emphasized: true
                            color: Theme.color.primary
                            font.letterSpacing: 1.2 * Theme.space.k
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space.sm

                            Repeater {
                                model: [
                                    {
                                        icon: "send",
                                        title: Lang.t("about.telegram"),
                                        desc: Lang.t("about.telegramDesc"),
                                        url: "https://t.me/eproggerspeoples",
                                        displayUrl: "t.me/eproggerspeoples",
                                        accent: Theme.color.primary,
                                        container: Theme.color.primaryContainer,
                                        fgContainer: Theme.color.fgPrimaryContainer
                                    },
                                    {
                                        icon: "code",
                                        title: Lang.t("about.github"),
                                        desc: Lang.t("about.githubDesc"),
                                        url: "https://github.com/Edgit13/Edots-rice",
                                        displayUrl: "github.com/Edgit13/Edots-rice",
                                        accent: Theme.color.secondary,
                                        container: Theme.color.secondaryContainer,
                                        fgContainer: Theme.color.fgSecondaryContainer
                                    },
                                    {
                                        icon: "wallpaper",
                                        title: Lang.t("about.wallpapers"),
                                        desc: Lang.t("about.wallpapersDesc"),
                                        url: "https://github.com/Edgit13/Edot-Wallpapers",
                                        displayUrl: "github.com/Edgit13/Edot-Wallpapers",
                                        accent: Theme.color.tertiary,
                                        container: Theme.color.tertiaryContainer,
                                        fgContainer: Theme.color.fgTertiaryContainer
                                    }
                                ]

                                Rectangle {
                                    id: linkCard
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    implicitHeight: linkRow.implicitHeight + Theme.space.md * 2
                                    radius: Theme.shape.card
                                    color: linkCardMa.pressed ? Theme.color.surfaceContainerHighest
                                         : linkCardMa.containsMouse ? Theme.color.surfaceContainerHigh
                                         : Theme.color.surfaceContainer
                                    border.width: 1
                                    border.color: linkCardMa.containsMouse ? linkCard.modelData.accent : Theme.color.outlineVariant

                                    Behavior on color { MotionColorAnimation { role: "hover" } }
                                    Behavior on border.color { MotionColorAnimation { role: "hover" } }

                                    MouseArea {
                                        id: linkCardMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally(linkCard.modelData.url)
                                    }

                                    RowLayout {
                                        id: linkRow
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: Theme.space.lg
                                            rightMargin: Theme.space.md
                                        }
                                        spacing: Theme.space.md

                                        Rectangle {
                                            implicitWidth: Theme.components.dp(44)
                                            implicitHeight: Theme.components.dp(44)
                                            radius: Theme.shape.radius("md", height)
                                            color: linkCard.modelData.container
                                            scale: linkCardMa.containsMouse ? 1.08 : 1.0
                                            Behavior on scale { MotionAnimation { role: "morph" } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: linkCard.modelData.icon
                                                color: linkCard.modelData.fgContainer
                                                font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Theme.space.xxs

                                            RowLayout {
                                                spacing: Theme.space.sm
                                                ThemedText {
                                                    text: linkCard.modelData.title
                                                    style: Theme.type.titleSmall
                                                    emphasized: true
                                                }
                                                ThemedText {
                                                    text: linkCard.modelData.displayUrl
                                                    style: Theme.type.labelSmall
                                                    color: linkCard.modelData.accent
                                                }
                                            }

                                            ThemedText {
                                                Layout.fillWidth: true
                                                text: linkCard.modelData.desc
                                                style: Theme.type.bodySmall
                                                color: Theme.color.fgSurfaceVariant
                                                elide: Text.ElideRight
                                            }
                                        }

                                        RowLayout {
                                            spacing: Theme.space.xs

                                            MaterialIconButton {
                                                icon: "content_copy"
                                                tooltip: Lang.t("about.copyLink")
                                                onClicked: copyProc.copy(linkCard.modelData.url)
                                            }

                                            Rectangle {
                                                implicitWidth: Theme.components.buttonS
                                                implicitHeight: Theme.components.buttonS
                                                radius: Theme.shape.radius("full", height)
                                                color: linkOpenMa.containsMouse ? Theme.alpha(linkCard.modelData.accent, 0.15) : "transparent"
                                                Behavior on color { MotionColorAnimation { role: "hover" } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "open_in_new"
                                                    color: linkCard.modelData.accent
                                                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                                    x: (parent.width - width) / 2 + (linkCardMa.containsMouse ? 2 : 0)
                                                    y: (parent.height - height) / 2 + (linkCardMa.containsMouse ? -2 : 0)
                                                    Behavior on x { MotionAnimation { role: "hover" } }
                                                    Behavior on y { MotionAnimation { role: "hover" } }
                                                }

                                                MouseArea {
                                                    id: linkOpenMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: Qt.openUrlExternally(linkCard.modelData.url)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Key Features Grid ──
                        ThemedText {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space.md
                            Layout.leftMargin: Theme.space.md
                            text: Lang.t("about.features").toUpperCase()
                            style: Theme.type.labelMedium
                            emphasized: true
                            color: Theme.color.primary
                            font.letterSpacing: 1.2 * Theme.space.k
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: Theme.space.sm
                            columnSpacing: Theme.space.sm

                            Repeater {
                                model: [
                                    { icon: "lock",            title: Lang.t("about.fLockscreen"), desc: Lang.t("about.fLockscreenDesc") },
                                    { icon: "grid_view",       title: Lang.t("about.fMango"),      desc: Lang.t("about.fMangoDesc") },
                                    { icon: "space_dashboard", title: Lang.t("about.fBar"),        desc: Lang.t("about.fBarDesc") },
                                    { icon: "dashboard",       title: Lang.t("about.fDashboard"),  desc: Lang.t("about.fDashboardDesc") },
                                    { icon: "palette",         title: Lang.t("about.fTheming"),    desc: Lang.t("about.fThemingDesc") },
                                    { icon: "videocam",        title: Lang.t("about.fRecord"),     desc: Lang.t("about.fRecordDesc") }
                                ]

                                Rectangle {
                                    id: featBox
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    implicitHeight: featRow.implicitHeight + Theme.space.md * 2
                                    radius: Theme.shape.card
                                    color: featMa.containsMouse ? Theme.color.surfaceContainerHigh : Theme.color.surfaceContainer
                                    border.width: 1
                                    border.color: featMa.containsMouse ? Theme.alpha(Theme.color.primary, 0.45) : Theme.color.outlineVariant

                                    Behavior on color { MotionColorAnimation { role: "hover" } }
                                    Behavior on border.color { MotionColorAnimation { role: "hover" } }

                                    MouseArea {
                                        id: featMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    RowLayout {
                                        id: featRow
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: Theme.space.md
                                            rightMargin: Theme.space.md
                                        }
                                        spacing: Theme.space.md

                                        Rectangle {
                                            implicitWidth: Theme.components.dp(36)
                                            implicitHeight: Theme.components.dp(36)
                                            radius: Theme.shape.radius("md", height)
                                            color: Theme.color.secondaryContainer
                                            scale: featMa.containsMouse ? 1.08 : 1.0
                                            Behavior on scale { MotionAnimation { role: "morph" } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: featBox.modelData.icon
                                                color: Theme.color.fgSecondaryContainer
                                                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Theme.space.xxs

                                            ThemedText {
                                                Layout.fillWidth: true
                                                text: featBox.modelData.title
                                                style: Theme.type.titleSmall
                                                emphasized: true
                                            }

                                            ThemedText {
                                                Layout.fillWidth: true
                                                text: featBox.modelData.desc
                                                style: Theme.type.bodySmall
                                                color: Theme.color.fgSurfaceVariant
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── IPC & Terminal Shortcuts ──
                        ThemedText {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space.md
                            Layout.leftMargin: Theme.space.md
                            text: Lang.t("about.commands").toUpperCase()
                            style: Theme.type.labelMedium
                            emphasized: true
                            color: Theme.color.primary
                            font.letterSpacing: 1.2 * Theme.space.k
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space.listGap

                            Repeater {
                                model: [
                                    { label: "Settings window", cmd: "qs ipc call settingsapp toggle" },
                                    { label: "Bar position",    cmd: "qs ipc call bar setPosition top" },
                                    { label: "Lock screen",     cmd: "qs -p lockscreen/shell.qml" },
                                    { label: "Dashboard",       cmd: "qs ipc call dashboard toggle" }
                                ]

                                Rectangle {
                                    id: cmdBox
                                    required property var modelData
                                    required property int index

                                    property bool justCopied: false
                                    Timer {
                                        id: revertTimer
                                        interval: 2000
                                        repeat: false
                                        onTriggered: cmdBox.justCopied = false
                                    }

                                    readonly property real big: Theme.shape.cardLarge
                                    readonly property real small: Theme.shape.listInner

                                    Layout.fillWidth: true
                                    implicitHeight: cmdRow.implicitHeight + Theme.space.md * 2
                                    color: cmdMa.containsMouse ? Theme.color.surfaceContainerHigh : Theme.color.surfaceContainer

                                    topLeftRadius: index === 0 ? big : small
                                    topRightRadius: index === 0 ? big : small
                                    bottomLeftRadius: index === 3 ? big : small
                                    bottomRightRadius: index === 3 ? big : small

                                    Behavior on color { MotionColorAnimation { role: "hover" } }

                                    MouseArea {
                                        id: cmdMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            copyProc.copy(cmdBox.modelData.cmd)
                                            cmdBox.justCopied = true
                                            revertTimer.restart()
                                        }
                                    }

                                    RowLayout {
                                        id: cmdRow
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: Theme.space.lg
                                            rightMargin: Theme.space.md
                                        }
                                        spacing: Theme.space.md

                                        Text {
                                            text: "terminal"
                                            color: Theme.color.fgSurfaceVariant
                                            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                        }

                                        ThemedText {
                                            Layout.preferredWidth: Theme.components.dp(140)
                                            text: cmdBox.modelData.label
                                            style: Theme.type.bodyMedium
                                            emphasized: true
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: Theme.components.dp(32)
                                            radius: Theme.shape.radius("xs", height)
                                            color: Theme.color.surfaceContainerLowest
                                            border.width: 1
                                            border.color: Theme.color.outlineVariant

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: Theme.space.md
                                                anchors.rightMargin: Theme.space.md

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: cmdBox.modelData.cmd
                                                    color: Theme.color.primary
                                                    font.family: Theme.type.mono
                                                    font.pixelSize: Theme.type.bodySmall.size
                                                    elide: Text.ElideMiddle
                                                }
                                            }
                                        }

                                        Rectangle {
                                            implicitWidth: Theme.components.buttonS
                                            implicitHeight: Theme.components.buttonS
                                            radius: Theme.shape.radius("full", height)
                                            color: cmdBox.justCopied ? Theme.alpha(Theme.color.primary, 0.15)
                                                 : copyBtnMa.containsMouse ? Theme.alpha(Theme.color.fgSurface, Theme.components.stateHover) : "transparent"
                                            Behavior on color { MotionColorAnimation { role: "hover" } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: cmdBox.justCopied ? "check" : "content_copy"
                                                color: cmdBox.justCopied ? Theme.color.primary : Theme.color.fgSurfaceVariant
                                                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                                scale: cmdBox.justCopied ? 1.2 : 1.0
                                                Behavior on scale { MotionAnimation { role: "morph" } }
                                                Behavior on color { MotionColorAnimation { role: "hover" } }
                                            }

                                            MouseArea {
                                                id: copyBtnMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    copyProc.copy(cmdBox.modelData.cmd)
                                                    cmdBox.justCopied = true
                                                    revertTimer.restart()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; implicitHeight: Theme.space.lg }
                    }
                }
            }
        }
    }

    // ───────── Clipboard Feedback Toast & Process ─────────
    Process {
        id: copyProc
        function copy(str: string): void {
            command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "--", str]
            running = false
            running = true
            toastTimer.restart()
        }
    }

    Timer {
        id: toastTimer
        interval: 2200
        repeat: false
    }

    Rectangle {
        id: copyToast
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.space.xl
        anchors.horizontalCenter: parent.horizontalCenter
        z: 999
        visible: opacity > 0
        opacity: toastTimer.running ? 1 : 0
        y: toastTimer.running ? 0 : Theme.space.md
        Behavior on opacity { MotionAnimation { role: "fade" } }
        Behavior on y { MotionAnimation { role: "move" } }

        implicitWidth: toastRow.implicitWidth + Theme.space.xl * 2
        implicitHeight: Theme.components.dp(44)
        radius: Theme.shape.radius("full", height)
        color: Theme.color.inverseSurface
        border.width: 1
        border.color: Theme.alpha(Theme.color.primary, 0.4)

        RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: Theme.space.sm
            Text {
                text: "check_circle"
                color: Theme.color.primary
                font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
            }
            ThemedText {
                text: Lang.t("about.copied")
                style: Theme.type.labelLarge
                color: Theme.color.inverseOnSurface
            }
        }
    }
}
