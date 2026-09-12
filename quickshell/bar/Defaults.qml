pragma Singleton
import Quickshell
import QtQuick

// ==========================================================================
// Defaults.qml — НЕЗМІННИЙ (immutable) набір заводських значень Edots.
//
// Структурна гарантія "Default" пресета:
//   - values/limits оголошені readonly і ніколи не перезаписуються кодом;
//   - файл не імпортує Config/Presets (немає шляху запису);
//   - Config.resetAll() відновлює саме ці значення;
//   - Presets "Default" — віртуальний (файлу не існує), apply("Default")
//     викликає Config.resetAll(), тому перезаписати чи видалити його
//     неможливо фізично.
//
// Звідки взяті числа:
//   - appearance/pill/launcher/surfaces/workspaces/... — реальні значення,
//     витягнуті з PillShell.qml, LauncherSurface.qml, Workspaces.qml,
//     WifiSurface.qml тощо (заводський вигляд Edots);
//   - notifications — реальні значення з swaync/config.json;
//   - keybinds — реальні значення з mango/binds.conf;
//   - lock/blur/performance/behavior — підготовлені для фаз 9/12/13;
//     wiring до UI відбудеться там. Дані ≠ фейкові контроли: контроли
//     з'являться лише тоді, коли ключ матиме реальну дію.
//
// Нові ключі, додані пізніше в коді, безпечно підхоплюються: mergeLoaded()
// мовчки падає на default, якщо ключа немає в збереженому файлі.
// ==========================================================================

Singleton {
    id: root

    readonly property var values: ({
        appearance: {
            uiFont: "SF Pro Display",
            monoFont: "SF Mono",
            iconFont: "Material Symbols Rounded",
            baseTextSize: 12,
            uiScale: 1.0,
            density: "normal"          // compact | normal | spacious
        },
        pill: {
            idleHeight: 36,
            idleHorizontalPadding: 20,
            idleTopMargin: 4,
            expandedWidth: 480,
            expandedHeight: 300,
            expandedRadius: 28,
            borderWidthDefault: 1,
            borderWidthHover: 2,
            backgroundOpacity: 0.97,
            hoverScale: 1.03,
            morphDuration: 320,
            morphOvershoot: 1.05,
            radiusTransitionDuration: 220,
            scaleDuration: 220,
            scaleOvershoot: 1.8,
            borderTransitionDuration: 160,
            glowEnabled: true,
            glowBreathDuration: 1600,
            glowMinOpacity: 0.18,
            glowMaxOpacity: 0.42
        },
        bar: {
            position: "top",           // top | bottom (wiring: Phase 5)
            exclusionZoneGap: 5
        },
        modules: {
            order: ["workspaces", "clock", "wallpaper", "media", "wifi",
                    "link", "power", "mixer", "clipboard", "notifications",
                    "launcher", "settings"],
            workspaces: true,
            clock: true,
            wallpaper: true,
            media: true,
            wifi: true,
            link: true,
            power: true,
            mixer: true,
            clipboard: true,
            notifications: true,
            launcher: true,
            settings: true
        },
        launcher: {
            fieldHeight: 34,
            fieldRadius: 8,
            rowHeight: 46,
            iconSize: 24,
            rowSpacing: 4,
            iconTextSpacing: 10,
            fontSize: 12,
            subFontSize: 10,
            showDescriptions: true,
            maxResults: 50
        },
        surfaces: {
            margins: 14,
            radius: 10,
            wifiRowHeight: 38,
            linkRowHeight: 46,
            clipboardRowHeight: 32,
            powerRowHeight: 36,
            sliderHeight: 6
        },
        wallpaper: {
            directory: "~/Pictures/Wallpapers",
            gridColumns: 4,
            thumbAspect: 0.62,
            thumbRadius: 10,
            hoverScale: 1.05,
            transition: "wave",        // awww transition
            useWallpaperColors: true,  // "Use wallpaper colors" toggle (Phase 7)
            matugen: true
        },
        colors: {
            mode: "wallpaper",         // wallpaper | manual (Phase 7)
            accent: "",                // "" = follow wallpaper/matugen
            background: "",
            foreground: "",
            surface: ""
        },
        animations: {
            enabled: true,
            globalSpeed: 1.0           // множник тривалостей
        },
        blur: {
            enabled: true,             // споживачі: lock/surfaces (Phase 9/13)
            strength: 7
        },
        behavior: {
            hoverOpens: true,          // idle -> hover при наведенні
            escapeCloses: true,
            clickOutsideCloses: true,
            closeOnLaunch: true,
            autoCollapse: true,        // hover -> idle при виході миші
            rememberState: false       // не реалізовано (Phase 12)
        },
        performance: {
            reducedMotion: false,
            lowPower: false,
            thumbnailCache: true
        },
        workspaces: {
            count: 9,
            showNumbers: true,
            spacing: 6,
            buttonWidth: 24,
            buttonHeight: 22,
            radius: 6
        },
        network: {
            pollMs: 5000,              // Network.qml statsProc timer
            showTooltip: true
        },
        clipboard: {
            rowHeight: 32,
            imagePreview: true,
            confirmBeforeWipe: true
        },
        media: {
            showAlbumArt: true,
            showProgress: true,        // немає прогрес-бара зараз (Phase 10)
            controlsSize: 26,
            controlsSpacing: 28
        },
        notifications: {                // реальні значення swaync/config.json
            positionX: "center",
            positionY: "top",
            timeoutSec: 10,
            timeoutLowSec: 5,
            width: 400,
            iconSize: 48,
            transitionMs: 150
        },
        tray: {                         // nm-applet tray (немає QML-трея)
            iconSize: 16,
            spacing: 6
        },
        lock: {                         // Phase 13: native Quickshell lock
            enabled: false,             // false = swaylock (поточна поведінка)
            backgroundMode: "wallpaper",// wallpaper | color
            blur: true,
            blurStrength: 7,
            dimAmount: 0.4,
            showClock: true,
            showDate: true,
            showUsername: true,
            clockPosition: "center",    // top | center | bottom
            clockSize: 64,
            dateFormat: "ddd, MMM d",
            animationDuration: 300,
            showLockedText: true
        },
        keybinds: {                     // реальні значення mango/binds.conf
            launcher: "SUPER Space",
            wallpaper: "SUPER C",
            clipboard: "SUPER V",
            wifi: "SUPER W",
            mixer: "SUPER X",
            power: "SUPER O",
            settings: "SUPER A",
            close: "SUPER Escape",
            lock: "SUPER L"
        }
    })

    // Валідаційні межі для Config.set()/replaceAll().
    // Ключ: "категорія.ключ". min/max — клемп для чисел; options — enum.
    // Ключів тут може бути МЕНШЕ, ніж values (не всі потребують меж).
    readonly property var limits: ({
        "appearance.baseTextSize":   { min: 8, max: 24 },
        "appearance.uiScale":        { min: 0.75, max: 1.5 },
        "appearance.density":        { options: ["compact", "normal", "spacious"] },

        "pill.idleHeight":           { min: 20, max: 80 },
        "pill.idleHorizontalPadding":{ min: 4, max: 60 },
        "pill.idleTopMargin":        { min: 0, max: 40 },
        "pill.expandedWidth":        { min: 320, max: 1200 },
        "pill.expandedHeight":       { min: 200, max: 900 },
        "pill.expandedRadius":       { min: 0, max: 60 },
        "pill.borderWidthDefault":   { min: 0, max: 6 },
        "pill.borderWidthHover":     { min: 0, max: 8 },
        "pill.backgroundOpacity":    { min: 0.3, max: 1.0 },
        "pill.hoverScale":           { min: 1.0, max: 1.2 },
        "pill.morphDuration":        { min: 0, max: 2000 },
        "pill.morphOvershoot":       { min: 0.5, max: 2.5 },
        "pill.radiusTransitionDuration": { min: 0, max: 1000 },
        "pill.scaleDuration":        { min: 0, max: 1000 },
        "pill.glowBreathDuration":   { min: 400, max: 8000 },
        "pill.glowMinOpacity":       { min: 0.0, max: 1.0 },
        "pill.glowMaxOpacity":       { min: 0.0, max: 1.0 },

        "bar.position":              { options: ["top", "bottom"] },
        "bar.exclusionZoneGap":      { min: 0, max: 40 },

        "launcher.fieldHeight":      { min: 24, max: 64 },
        "launcher.fieldRadius":      { min: 0, max: 24 },
        "launcher.rowHeight":        { min: 28, max: 80 },
        "launcher.iconSize":         { min: 16, max: 48 },
        "launcher.rowSpacing":       { min: 0, max: 20 },
        "launcher.fontSize":         { min: 8, max: 20 },
        "launcher.subFontSize":      { min: 7, max: 16 },
        "launcher.maxResults":       { min: 5, max: 200 },

        "surfaces.margins":          { min: 0, max: 40 },
        "surfaces.wifiRowHeight":    { min: 28, max: 64 },
        "surfaces.linkRowHeight":    { min: 32, max: 72 },
        "surfaces.clipboardRowHeight": { min: 24, max: 56 },
        "surfaces.powerRowHeight":   { min: 28, max: 56 },
        "surfaces.sliderHeight":     { min: 2, max: 16 },

        "wallpaper.gridColumns":     { min: 2, max: 8 },
        "wallpaper.thumbAspect":     { min: 0.4, max: 1.0 },
        "wallpaper.hoverScale":      { min: 1.0, max: 1.3 },
        "wallpaper.useWallpaperColors": { options: [true, false] },

        "colors.mode":               { options: ["wallpaper", "manual"] },

        "animations.globalSpeed":    { min: 0.25, max: 3.0 },

        "blur.enabled":              { options: [true, false] },
        "blur.strength":             { min: 0, max: 30 },

        "workspaces.count":          { min: 1, max: 20 },
        "workspaces.spacing":        { min: 0, max: 20 },
        "workspaces.buttonWidth":    { min: 16, max: 48 },
        "workspaces.buttonHeight":   { min: 16, max: 48 },
        "workspaces.radius":         { min: 0, max: 20 },

        "network.pollMs":            { min: 1000, max: 60000 },

        "clipboard.rowHeight":       { min: 24, max: 56 },

        "media.controlsSize":        { min: 16, max: 48 },
        "media.controlsSpacing":     { min: 8, max: 60 },

        "notifications.timeoutSec":  { min: 1, max: 60 },
        "notifications.timeoutLowSec": { min: 1, max: 30 },
        "notifications.width":       { min: 200, max: 800 },
        "notifications.iconSize":    { min: 16, max: 96 },
        "notifications.positionX":   { options: ["left", "center", "right"] },
        "notifications.positionY":   { options: ["top", "bottom"] },

        "lock.enabled":              { options: [true, false] },
        "lock.backgroundMode":       { options: ["wallpaper", "color"] },
        "lock.blurStrength":         { min: 0, max: 30 },
        "lock.dimAmount":            { min: 0.0, max: 0.9 },
        "lock.clockPosition":        { options: ["top", "center", "bottom"] },
        "lock.clockSize":            { min: 24, max: 200 },
        "lock.animationDuration":    { min: 0, max: 2000 }
    })
}
