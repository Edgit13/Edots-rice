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
                design:           { type: "enum", options: ["material","nothing"], default: "material", label: "Design style", desc: "Material (default) or Nothing (monochrome, dot-matrix, red accent)." },
                transition:       { type: "enum", options: ["off","fade","dots","scan"], default: "dots", label: "Theme transition", desc: "Animation when switching design or light/dark." },
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
                style:       { type: "enum", options: ["full","pill"], default: "full", label: "Style", desc: "pill = compact island in the center" },
                openMode:    { type: "enum", options: ["morph","window","spotlight","drawer"], default: "morph", label: "Open mode", desc: "How modules open: morph / window / spotlight / drawer" },
                mode:        { type: "enum", options: ["compact","expanded","morphing"], default: "compact", label: "Mode" },
                elevation:   { type: "num", min: 0, max: 5, step: 1, default: 1, label: "Elevation" },
                mainMonitor: { type: "str", default: "", label: "Main monitor", desc: "Empty = first screen" },
                pillHover:         { type: "bool", default: true, label: "Pill: expand on hover", desc: "Show extra modules when hovering the pill." },
                pillEdgeGap:       { type: "num", min: 0, max: 32, step: 1, default: 8, label: "Pill: edge gap", suffix: "px" },
                pillCloseOnEscape: { type: "bool", default: true, label: "Pill: close on Esc" },
                perMonitor:  { type: "map", default: {}, hidden: true }
            }
        },
        widgets: {
            file: "widgets.json",
            label: "section.widgets",
            fields: {
                enabled:      { type: "bool", default: true, label: "Desktop widgets", desc: "Move them: qs ipc call widgets edit" },
                monitor:      { type: "str",  default: "", label: "Monitor", desc: "Empty = all screens" },
                anchor:       { type: "enum", options: ["top-left","top","top-right","left","center","right","bottom-left","bottom","bottom-right"], default: "top-right", label: "Position" },
                arrange:      { type: "enum", options: ["row","column","grid"], default: "row", label: "Layout" },
                margin:       { type: "num", min: 0, max: 300, step: 4, default: 48, label: "Edge margin", suffix: "px" },
                spacing:      { type: "num", min: 0, max: 64, step: 2, default: 16, label: "Spacing", suffix: "px" },
                scale:        { type: "num", min: 0.5, max: 2.0, step: 0.05, default: 1.0, label: "Size", suffix: "×" },
                opacity:      { type: "num", min: 0.2, max: 1.0, step: 0.05, default: 1.0, label: "Opacity" },
                colorStyle:   { type: "enum", options: ["mixed","primary","secondary","tertiary","surface"], default: "mixed", label: "Colors", desc: "mixed = each widget has its own accent" },
                clockEnabled:    { type: "bool", default: true, label: "Clock" },
                clockStyle:      { type: "enum", options: ["digital","analog"], default: "digital", label: "Clock style" },
                clockShape:      { type: "enum", options: ["cookie","flower","sunny","circle","squircle","pill","rounded"], default: "cookie", label: "Clock shape" },
                weatherEnabled:  { type: "bool", default: true, label: "Weather" },
                weatherShape:    { type: "enum", options: ["cookie","flower","sunny","circle","squircle","pill","rounded"], default: "flower", label: "Weather shape" },
                mediaEnabled:    { type: "bool", default: true, label: "Media" },
                mediaShape:      { type: "enum", options: ["cookie","flower","sunny","circle","squircle","pill","rounded"], default: "pill", label: "Media shape" },
                mediaHideIdle:   { type: "bool", default: true, label: "Hide media when nothing plays" },
                resourcesEnabled:{ type: "bool", default: true, label: "System resources" },
                resourcesShape:  { type: "enum", options: ["cookie","flower","sunny","circle","squircle","pill","rounded"], default: "sunny", label: "Resources shape" },
                edit:         { type: "bool", default: false, label: "Edit mode", desc: "Drag widgets on the desktop" },
                bgStyle:      { type: "enum", options: ["filled","glass","outline","none"], default: "filled", label: "Background", desc: "Widget background style" },
                bgOpacity:    { type: "num", min: 0.1, max: 1.0, step: 0.05, default: 1.0, label: "Background opacity" },
                preset:       { type: "enum", options: ["custom","corner","stack","desk","centered","minimal","outline"], default: "custom", label: "Preset", desc: "Applies on select" },
                clockPlacement:     { type: "enum", options: ["auto","free"], default: "auto", label: "Clock placement" },
                weatherPlacement:   { type: "enum", options: ["auto","free"], default: "auto", label: "Weather placement" },
                mediaPlacement:     { type: "enum", options: ["auto","free"], default: "auto", label: "Media placement" },
                resourcesPlacement: { type: "enum", options: ["auto","free"], default: "auto", label: "Resources placement" },
                clockX:     { type: "num", min: 0, max: 1, step: 0.001, default: 0.03, hidden: true },
                clockY:     { type: "num", min: 0, max: 1, step: 0.001, default: 0.06, hidden: true },
                weatherX:   { type: "num", min: 0, max: 1, step: 0.001, default: 0.97, hidden: true },
                weatherY:   { type: "num", min: 0, max: 1, step: 0.001, default: 0.06, hidden: true },
                mediaX:     { type: "num", min: 0, max: 1, step: 0.001, default: 0.5,  hidden: true },
                mediaY:     { type: "num", min: 0, max: 1, step: 0.001, default: 0.95, hidden: true },
                resourcesX: { type: "num", min: 0, max: 1, step: 0.001, default: 0.97, hidden: true },
                resourcesY: { type: "num", min: 0, max: 1, step: 0.001, default: 0.55, hidden: true }
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
        layout: {
            file: "bar.json",
            label: "section.layout",
            fields: {
                active: { type: "layout", default: "dwindle", label: "Window layout", desc: "Applied to all tags. Needs source=~/.config/mango/layout.conf in config.conf.", path: "layout.active",
                          options: ["dwindle", "tile", "scroller", "monocle", "grid", "deck", "center_tile", "right_tile", "vertical_tile", "vertical_scroller", "vertical_grid", "vertical_deck", "fair", "vertical_fair"] },
                cycle:  { type: "str", default: "dwindle,scroller,grid,monocle", label: "Layout cycle", desc: "Comma-separated list for switch_layout (SUPER+Tab).", path: "layout.cycle" }
            }
        },
        gamemode: {
            file: "bar.json",
            label: "section.gamemode",
            fields: {
                effects: { type: "bool", default: true, label: "Disable compositor effects", desc: "Blur, shadows, rounded corners and animations in MangoWM (setoption).", path: "gamemode.effects" },
                tearing: { type: "bool", default: true, label: "Allow tearing", desc: "Fullscreen games may skip vsync for lower latency.", path: "gamemode.tearing" },
                power:   { type: "bool", default: true, label: "Performance power profile", desc: "power-profiles-daemon → performance, restored afterwards.", path: "gamemode.power" },
                idle:    { type: "bool", default: true, label: "Pause idle lock", desc: "swayidle is paused so the screen stays on.", path: "gamemode.idle" },
                dnd:     { type: "bool", default: true, label: "Do not disturb", path: "gamemode.dnd" },
                motion:  { type: "bool", default: true, label: "Disable shell animations", path: "gamemode.motion" },
                notify:  { type: "bool", default: true, label: "Notify on toggle", path: "gamemode.notify" },
                flatBar: { type: "bool", default: true, label: "Flat bar (no corners)", desc: "Full bar loses rounded corners, outer gap and shadow while game mode is on.", path: "gamemode.flatBar" },
                overlay:        { type: "bool", default: true, label: "Performance overlay", desc: "FPS and CPU/GPU load above all windows, even fullscreen games.", path: "gamemode.overlay" },
                overlayFps:     { type: "bool", default: true, label: "Overlay: FPS", path: "gamemode.overlayFps" },
                overlayCpu:     { type: "bool", default: true, label: "Overlay: CPU load", path: "gamemode.overlayCpu" },
                overlayGpu:     { type: "bool", default: true, label: "Overlay: GPU load", desc: "AMD (sysfs) and NVIDIA (nvidia-smi).", path: "gamemode.overlayGpu" },
                overlayTemps:   { type: "bool", default: false, label: "Overlay: temperatures", path: "gamemode.overlayTemps" },
                overlayPos:     { type: "enum", options: ["top-left","top-right","bottom-left","bottom-right"], default: "top-left", label: "Overlay position", path: "gamemode.overlayPos" },
                overlayScale:   { type: "num", min: 0.6, max: 2.5, step: 0.1, default: 1.0, label: "Overlay size", suffix: "×", path: "gamemode.overlayScale" },
                overlayOpacity: { type: "num", min: 0.2, max: 1.0, step: 0.05, default: 0.85, label: "Overlay opacity", path: "gamemode.overlayOpacity" },
                fpsSource:      { type: "enum", options: ["auto","display","mangohud"], default: "auto", label: "FPS source", desc: "auto: MangoHud log when fresh, otherwise display refresh rate.", path: "gamemode.fpsSource" },
                mangohudDir:    { type: "str", default: "/tmp/MangoHud", label: "MangoHud log folder", desc: "output_folder in MangoHud.conf; logging must be on (autostart_log).", path: "gamemode.mangohudDir" }
            }
        },
        record: {
            file: "bar.json",
            label: "section.record",
            fields: {
                audio:   { type: "enum", default: "system", options: ["system", "mic", "none"], label: "Audio", desc: "System sound, microphone or no audio.", path: "record.audio" },
                fps:     { type: "num", min: 10, max: 120, step: 5, default: 30, label: "Frame rate", suffix: " fps", path: "record.fps" },
                encoder: { type: "enum", default: "software", options: ["software", "vaapi"], label: "Encoder", desc: "vaapi uses the GPU (h264_vaapi) — much lighter on the CPU.", path: "record.encoder" },
                dir:     { type: "str", default: "~/Videos/Recordings", label: "Save folder", path: "record.dir" },
                notify:  { type: "bool", default: true, label: "Notify when saved", desc: "With a thumbnail and Open / Show in folder / Copy path actions.", path: "record.notify" }
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
        { name: "page.widgets",    icon: "widgets",         cats: ["widgets"] },
        { name: "page.osd",        icon: "volume_up",       cats: ["osd"] },
        { name: "page.notif",      icon: "notifications",   cats: ["notif"] },
        { name: "page.layout",     icon: "view_quilt",      cats: ["layout"] },
        { name: "page.gamemode",   icon: "sports_esports",  cats: ["gamemode"] },
        { name: "page.record",     icon: "videocam",        cats: ["record"] },
        { name: "page.lockscreen", icon: "lock",            cats: ["lockscreen"] },
        { name: "page.clock",      icon: "schedule",        cats: ["clock"] },
        { name: "page.wallpapers", icon: "wallpaper",       cats: [] },
        { name: "page.about",      icon: "info",            cats: [] }
    ]
}
