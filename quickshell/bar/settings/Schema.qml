pragma Singleton
import Quickshell
import QtQuick

// Schema.qml — опис усіх налаштувань. Один рядок = одна опція.
Singleton {
    id: root

    readonly property var schema: ({
        general: {
            file: "general.json",
            label: "section.general",
            fields: {
                language:        { type: "enum", options: ["uk","en"], default: "uk", label: "Language" },
                userName:        { type: "str",  default: "", label: "Display name", desc: "Empty = system user" },
                autoStart:       { type: "bool", default: false, label: "Open dashboard on login" },
                notifEnabled:    { type: "bool", default: true,  label: "Desktop notifications" },
                weatherCity:     { type: "str",  default: "", label: "Weather city", desc: "Empty = auto-detect by IP" },
                terminalCommand: { type: "str",  default: "ghostty", label: "Terminal" },
                fileManager:     { type: "str",  default: "nautilus", label: "File manager" },
                browser:         { type: "str",  default: "firefox", label: "Browser" }
            }
        },
        theme: {
            file: "theme.json",
            label: "section.appearance",
            fields: {
                mode:             { type: "enum", options: ["system","light","dark"], default: "dark", label: "Color mode", desc: "Follow system or force dark/light." },
                dynamicColor:     { type: "bool", default: true, label: "Dynamic colors from wallpaper" },
                accent:           { type: "color", default: "#74e7c8", label: "Custom accent" },
                cornerStyle:      { type: "enum", options: ["material","expressive","rounded"], default: "expressive", label: "Corner style" },
                uiScale:          { type: "num", min: 0.75, max: 1.5, step: 0.05, default: 1.0, label: "UI scale", suffix: "×" },
                animations:       { type: "bool", default: true, label: "Animations" },
                expressiveMotion: { type: "bool", default: true, label: "Expressive motion" },
                reduceMotion:     { type: "bool", default: false, label: "Reduce motion" },
                animationSpeed:   { type: "num", min: 0.25, max: 3.0, step: 0.05, default: 1.0, label: "Animation speed", suffix: "×" }
            }
        },
        bar: {
            file: "bar.json",
            label: "section.bar",
            fields: {
                position:    { type: "enum", options: ["top","bottom","left","right"], default: "top", label: "Position" },
                mode:        { type: "enum", options: ["compact","expanded","morphing"], default: "compact", label: "Mode" },
                elevation:   { type: "num", min: 0, max: 5, step: 1, default: 1, label: "Elevation" },
                mainMonitor: { type: "str", default: "", label: "Main monitor", desc: "Empty = first screen" },
                perMonitor:  { type: "map", default: {}, hidden: true }
            }
        },
        modules: {
            file: "bar.json",
            label: "section.modules",
            fields: {
                order:         { type: "arr",  default: ["workspaces","clock","launcher","window","media","mixer","wifi","notifications","battery","power"], path: "modules.order", hidden: true },
                workspaces:    { type: "bool", default: true, label: "Workspaces", path: "modules.workspaces" },
                clock:         { type: "bool", default: true, label: "Clock", path: "modules.clock" },
                launcher:      { type: "bool", default: true, label: "Launcher", path: "modules.launcher" },
                window:        { type: "bool", default: true, label: "Window title", path: "modules.window" },
                media:         { type: "bool", default: true, label: "Media", path: "modules.media" },
                resources: { type: "bool", default: true, label: "Resources", path: "modules.resources" },
                mixer:         { type: "bool", default: true, label: "Volume", path: "modules.mixer" },
                wifi:          { type: "bool", default: true, label: "Wi-Fi", path: "modules.wifi" },
                notifications: { type: "bool", default: true, label: "Notifications", path: "modules.notifications" },
                battery:       { type: "bool", default: true, label: "Battery", path: "modules.battery" },
                power:         { type: "bool", default: true, label: "Power", path: "modules.power" }
            }
        },
        osd: {
            file: "bar.json",
            label: "section.osd",
            fields: {
                enabled:    { type: "bool", default: true, label: "Show OSD", desc: "Pill on volume / brightness change.", path: "osd.enabled" },
                volume:     { type: "bool", default: true, label: "Volume", path: "osd.volume" },
                brightness: { type: "bool", default: true, label: "Brightness", path: "osd.brightness" },
                position:   { type: "pos",  default: "bottom", label: "Position", desc: "Where on the screen the OSD appears.", path: "osd.position" },
                margin:     { type: "num", min: 24, max: 400, step: 4, default: 110, label: "Distance from edge", suffix: " px", path: "osd.margin" },
                size:       { type: "num", min: 0.6, max: 1.6, step: 0.05, default: 1.0, label: "Size", suffix: "×", path: "osd.size" },
                duration:   { type: "num", min: 0.5, max: 5, step: 0.1, default: 1.8, label: "Duration", suffix: " s", path: "osd.duration" }
            }
        },
        notif: {
            file: "bar.json",
            label: "section.notif",
            fields: {
                dnd:        { type: "bool", default: false, label: "Do not disturb", desc: "No popups (critical ones still show).", path: "notif.dnd" },
                toasts:     { type: "bool", default: true, label: "Popups", desc: "Cards that slide in at the screen edge.", path: "notif.toasts" },
                bar:        { type: "bool", default: true, label: "Show in bar", desc: "Bell expands into the latest notification.", path: "notif.bar" },
                position:   { type: "pos",  default: "top-right", label: "Popup position", desc: "Where popups appear; the center opens on the same side.", path: "notif.position" },
                margin:     { type: "num", min: 8, max: 200, step: 4, default: 16, label: "Distance from edge", suffix: " px", path: "notif.margin" },
                width:      { type: "num", min: 280, max: 560, step: 10, default: 380, label: "Width", suffix: " px", path: "notif.width" },
                timeout:    { type: "num", min: 1, max: 30, step: 1, default: 6, label: "Timeout (normal)", suffix: " s", path: "notif.timeout" },
                timeoutLow: { type: "num", min: 1, max: 20, step: 1, default: 4, label: "Timeout (low)", suffix: " s", path: "notif.timeoutLow" },
                maxVisible: { type: "num", min: 1, max: 8, step: 1, default: 4, label: "Max popups", path: "notif.maxVisible" }
            }
        },
        clock: {
            file: "clock.json",
            label: "section.clock",
            fields: {
                hour12:           { type: "bool", default: false, label: "12-hour" },
                showSeconds:      { type: "bool", default: false, label: "Show seconds" },
                dateFormat:       { type: "str",  default: "d MMMM", label: "Date format" },
                fullDateFormat:   { type: "str",  default: "dddd, d MMMM", label: "Full date format" },
                utcOffsetMinutes: { type: "num", nullable: true, default: null, hidden: true },
                zoneLabel:        { type: "str",  default: "", hidden: true }
            }
        },
        lockscreen: {
            file: "lockscreen.json",
            label: "section.lockscreen",
            fields: {
                enabled:        { type: "bool", default: true, label: "Use Edots lock screen" },
                blurStrength:   { type: "num", min: 0, max: 1, step: 0.05, default: 0.35, label: "Blur strength" },
                blurRadius:     { type: "num", min: 8, max: 128, step: 8, default: 32, label: "Blur radius", suffix: " px" },
                scrimOpacity:   { type: "num", min: 0, max: 1, step: 0.05, default: 0.55, label: "Dim overlay" },
                kenBurns:       { type: "bool", default: true, label: "Ken Burns zoom" },
                parallax:       { type: "bool", default: true, label: "Mouse parallax" },
                floatingShapes: { type: "bool", default: true, label: "Floating accent shapes" },
                clockSize:      { type: "num", min: 60, max: 200, step: 4, default: 112, label: "Clock size", suffix: " px" },
                greeting:       { type: "bool", default: true, label: "Show greeting pill" },
                passwordStyle:  { type: "enum", options: ["dots","shapes","text"], default: "shapes", label: "Password style" },
                powerButtons:   { type: "bool", default: true, label: "Power buttons" },
                successFlash:   { type: "bool", default: true, label: "Success flash" }
            }
        },
        colors: {
            file: "colors.json",
            label: "section.colors",
            fields: {
                bg0:    { type: "color", default: "#060f0c", label: "Background — deepest" },
                bg1:    { type: "color", default: "#0a1a16", label: "Surface" },
                bg2:    { type: "color", default: "#0f2922", label: "Container" },
                bg3:    { type: "color", default: "#15372e", label: "Container high" },
                bg4:    { type: "color", default: "#1c4a3d", label: "Container highest" },
                fg:     { type: "color", default: "#dae7e3", label: "Foreground" },
                grey1:  { type: "color", default: "#31816c", label: "Outline" },
                grey2:  { type: "color", default: "#90d5c2", label: "Variant" },
                accent: { type: "color", default: "#74e7c8", label: "Accent" },
                red:    { type: "color", default: "#d27c79", label: "Error" },
                blue:   { type: "color", default: "#d27c79", label: "Secondary" },
                purple: { type: "color", default: "#d1df9f", label: "Tertiary" }
            }
        }
    })

    readonly property var pages: [
        { name: "page.general",    icon: "tune",            cats: ["general"] },
        { name: "page.appearance", icon: "palette",         cats: ["theme"] },
        { name: "page.colors",     icon: "format_paint",    cats: ["colors"] },
        { name: "page.bar",        icon: "space_dashboard", cats: ["bar", "modules"] },
        { name: "page.osd",        icon: "volume_up",       cats: ["osd"] },
        { name: "page.notif",      icon: "notifications",   cats: ["notif"] },
        { name: "page.lockscreen", icon: "lock",            cats: ["lockscreen"] },
        { name: "page.clock",      icon: "schedule",        cats: ["clock"] },
        { name: "page.about",      icon: "info",            cats: [] }
    ]
}
