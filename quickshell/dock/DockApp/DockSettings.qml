pragma Singleton

import Quickshell
import Quickshell.Io

// The dock's settings file, its parsed contents and the writes back into it.
//
// This lives outside DockWindow because the "enabled" flag decides whether a
// DockWindow exists at all: DockLoader reads it here to instantiate the dock
// (or not), and the dock IPC — which has to work while the dock is disabled —
// writes it here.
Singleton {
    id: root

    // One settings file:
    //
    //   ~/.config/quickshell-dock/config.json
    //
    // It is created (empty) on first start if it does not exist yet. The file
    // is merged over the built-in defaults, so a partial or entirely empty
    // file still leaves every value defined — which is what lets the user edit
    // it by hand and only write down what they want to change. Everything the
    // dock writes itself (enabled, autohide, the pinned app list) goes into
    // the same file. DockApp/config.json documents these defaults and must be
    // kept in sync with them.
    readonly property var defaultSettings: ({
        "dock":   { "enabled": true, "autohide": false, "iconSize": 28,
                    "spacing": 8, "marginBottom": 8, "reserveSpace": true,
                    "hideDelay": 400, "launcherButton": true,
                    "launcherCommand": "qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleLauncher || qs -d -p ~/.config/quickshell/bar/shell.qml",
                    "editorCommand": "" },
        "pill":   { "radius": 26, "padding": 8, "animationDuration": 300 },
        "border": { "width": 0, "colorTop": "", "colorBottom": "" },
        "opacity":{ "normal": 0.92 },
        "theme":  { "colorsFile": "~/.config/quickshell/dock-colors.json" },
        "apps":   { "pinned": ["firefox", "kitty"] }
    })

    property var settings: defaultSettings

    readonly property bool enabled: settings.dock.enabled
    readonly property bool autohide: settings.dock.autohide
    readonly property bool launcherButton: settings.dock.launcherButton

    // Whether a dock context menu is currently open. The dock window sets it;
    // DockClickCatcher reads it to know when to swallow outside clicks (the
    // portable replacement for a compositor focus grab on MangoWM/Sway).
    property bool menuOpen: false

    // Whether the settings dialog is open. DockLoader creates the dialog while
    // this is set; the launcher button's menu and `qs ipc call dock settings`
    // set it, and closing the dialog clears it. Kept here rather than on the
    // dock window so the dialog also opens while the dock is turned off.
    property bool dialogOpen: false

    // The settings file has reported back (loaded, or missing and created), so
    // `settings` holds the values from disk rather than the built-in defaults.
    //
    // DockLoader waits for this before creating the dock. The file reports
    // asynchronously, so without the gate the window is built from the defaults
    // — autohide off, space reserved — and only corrects itself a moment later.
    // The compositor does not reliably pick up the exclusive zone dropping
    // back to 0 that soon after the layer surface is created, which leaves an
    // autohiding dock holding a gap open at the bottom of the screen for the
    // session.
    property bool ready: false

    // Guards the create pass below so a file that cannot be written (read-only
    // home, no permissions) does not retry on every reload.
    property bool seeded: false

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell-dock/config.json"
        blockLoading: true
        printErrors: false
        // `ready` is set last, after the values are in place: it releases
        // DockLoader, and a binding fires the moment it is assigned.
        onLoaded: { root.applySettings(); root.ready = true }
        onLoadFailed: {
            // First miss: create the file, then come back through reload().
            // Qt.callLater because this can fire while the component is still
            // being built, before seedProc exists.
            if (!root.seeded) {
                root.seeded = true
                Qt.callLater(function() { seedProc.running = true })
                return
            }
            root.applySettings()
            root.ready = true
        }
    }

    // Creates ~/.config/quickshell-dock/config.json (and its directory) when
    // it is missing, as an empty document for the user to fill.
    Process {
        id: seedProc
        command: ["bash", "-c",
            'd="$HOME/.config/quickshell-dock"; f="$d/config.json";'
            + ' mkdir -p "$d" || exit 1;'
            + ' [ -f "$f" ] || printf "{\\n}\\n" > "$f"']
        onExited: settingsFile.reload()
    }

    function reloadSettings(): void {
        settingsFile.reload()
        console.log("Dock reload: re-reading dock settings")
        applySettings()
    }

    // Parse a settings document that may carry a /* ... */ comment block and —
    // being hand-edited — trailing commas, which strict JSON.parse rejects.
    // Returns undefined when the text is empty or unparseable. Never throws.
    function parseSettings(src) {
        if (!src)
            return undefined
        let raw = src.replace(/\/\*[\s\S]*?\*\//g, "")
        if (raw.trim() === "")
            return undefined
        try {
            return JSON.parse(raw)
        } catch (e) {
            try {
                return JSON.parse(raw.replace(/,(\s*[}\]])/g, "$1"))
            } catch (e2) {
                console.warn("dock settings: could not parse the settings file,"
                    + " ignoring it:", e2)
                return undefined
            }
        }
    }

    // Merge one settings document (as text) over an already-built settings
    // object, key by key. Empty or unparseable text is ignored so a
    // missing/partial file never clears previously merged values.
    function mergeSettings(merged, src): void {
        let parsed = parseSettings(src)
        if (parsed === undefined)
            return
        for (let group in parsed)
            for (let key in parsed[group])
                if (merged[group] !== undefined)
                    merged[group][key] = parsed[group][key]
    }

    // Rebuild the settings object: built-in defaults with the settings file
    // merged on top, so a file that only carries the keys the user changed (or
    // the dock wrote back) keeps the defaults for everything else. An explicit
    // text can be passed (e.g. right after a write) so the merge does not depend
    // on the FileView buffer having refreshed yet.
    function applySettings(text): void {
        let merged = JSON.parse(JSON.stringify(root.defaultSettings))
        mergeSettings(merged, (text !== undefined) ? text : settingsFile.text())
        root.settings = merged
    }

    // Persist a dock.<key> boolean into the settings file and return the updated
    // text. A regex replace keeps the file's formatting and comments intact when
    // the key is already present; otherwise the parsed document is rewritten. An
    // unparseable, non-empty file is left untouched rather than overwritten.
    function persistDockFlag(key, on): string {
        let src = settingsFile.text()
        let re = new RegExp('("' + key + '"\\s*:\\s*)(true|false)')
        let updated
        if (re.test(src)) {
            updated = src.replace(re, "$1" + (on ? "true" : "false"))
        } else {
            let obj = root.parseSettings(src)
            if (obj === undefined && src && src.trim() !== "") {
                console.warn("dock settings: the settings file is not valid"
                    + " JSON; leaving it untouched instead of overwriting.")
                return src
            }
            if (typeof obj !== "object" || obj === null)
                obj = {}
            if (obj.dock === undefined)
                obj.dock = {}
            obj.dock[key] = on
            updated = JSON.stringify(obj, null, 4) + "\n"
        }
        settingsFile.setText(updated)
        return updated
    }

    // Persist the pinned app list into the settings file. Unlike the boolean
    // flags this always rewrites the JSON document (an array cannot be patched
    // in place with a regex without mangling hand-formatted files), so a comment
    // block in the file is lost on the first pin/unpin. An unparseable, non-empty
    // file is left untouched.
    function persistPinned(list): void {
        let src = settingsFile.text()
        let obj = root.parseSettings(src)
        if (obj === undefined && src && src.trim() !== "") {
            console.warn("dock settings: the settings file is not valid JSON;"
                + " not writing the pinned list.")
            return
        }
        if (typeof obj !== "object" || obj === null)
            obj = {}
        if (obj.apps === undefined)
            obj.apps = {}
        obj.apps.pinned = list
        let updated = JSON.stringify(obj, null, 4) + "\n"
        settingsFile.setText(updated)
        applySettings(updated)
    }

    // Open the settings file in dock.editorCommand, which gets the file path as
    // its last argument. An empty command, or one whose program is not found,
    // falls back to xdg-open — the default application for JSON files. The
    // command is passed as an argument rather than spliced into the script, so
    // quotes in it cannot break the fallback logic.
    function editConfig(): void {
        Quickshell.execDetached(["bash", "-c",
            'f="$HOME/.config/quickshell-dock/config.json"; c="${1/#\\~/$HOME}";'
            + ' if [ -n "$c" ] && command -v "${c%% *}" >/dev/null 2>&1;'
            + ' then eval "$c \\"\\$f\\""; else exec xdg-open "$f"; fi',
            "dock-edit", root.settings.dock.editorCommand || ""])
    }

    function setEnabled(on: bool): void {
        applySettings(persistDockFlag("enabled", on))
    }

    function setAutohide(on: bool): void {
        applySettings(persistDockFlag("autohide", on))
    }

    function setLauncherButton(on: bool): void {
        applySettings(persistDockFlag("launcherButton", on))
    }
}
