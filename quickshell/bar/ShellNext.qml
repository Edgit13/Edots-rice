pragma ComponentBehavior: Bound

import "root:/"
import "root:/shell"
import "root:/settings"
import "root:/theme"
import Quickshell
import Quickshell.Io
import QtQuick

// ShellNext — Material 3 Expressive Shell з повною підтримкою MangoWM.
// Керується через IPC та модуль бару.
//
// Дашборд більше НЕ окреме вікно: він живе всередині BarWindow (DashboardSurface)
// і відкривається сигналами ShellState.openDashboardRequested/toggle/close,
// які слухає DashboardSurface на кожному моніторі.
ShellRoot {
    id: root

    // Windows & Overlays
    SettingsWindow { id: settingsWindow }
    TaskManagerWindow { id: taskManagerWindow }

    Connections {
        target: ShellState
        // дашборд обробляє сам DashboardSurface усередині BarWindow (per-monitor)

        function onOpenSettingsRequested() { settingsWindow.open() }
        function onToggleSettingsRequested() { settingsWindow.toggle() }
        function onCloseSettingsRequested() { settingsWindow.close() }

        function onOpenTasksRequested() { taskManagerWindow.open() }
        function onToggleTasksRequested() { taskManagerWindow.toggle() }
        function onCloseTasksRequested() { taskManagerWindow.close() }
    }

    // IPC Handlers for MangoWM binds compatibility (mango/binds.conf)
    IpcHandler {
        target: "pill"

        function showLauncher(): void { ShellState.openSurface("launcher") }
        function toggleLauncher(): void { ShellState.toggleSurface("launcher") }

        function showWallpaper(): void { ShellState.openSurface("wallpaper") }
        function toggleWallpaper(): void { ShellState.toggleSurface("wallpaper") }

        function showClipboard(): void { ShellState.openSurface("clipboard") }
        function toggleClipboard(): void { ShellState.toggleSurface("clipboard") }

        function showMixer(): void { ShellState.openSurface("mixer") }
        function toggleMixer(): void { ShellState.toggleSurface("mixer") }

        function showWifi(): void { ShellState.openSurface("wifi") }
        function toggleWifi(): void { ShellState.toggleSurface("wifi") }

        function showMedia(): void { ShellState.openSurface("media") }
        function toggleMedia(): void { ShellState.toggleSurface("media") }

        function showPower(): void { ShellState.openSurface("power") }
        function togglePower(): void { ShellState.toggleSurface("power") }

        function showSettings(): void { settingsWindow.toggle() }
        function toggleSettings(): void { settingsWindow.toggle() }

        function close(): void { ShellState.closeSurfaces() }
    }

    IpcHandler {
        target: "launcher"
        function open(): void { ShellState.openSurface("launcher") }
    }

    IpcHandler {
        target: "dashboard"
        function open(): void { ShellState.openDashboard() }
        function toggle(): void { ShellState.toggleDashboard() }
        function close(): void { ShellState.closeDashboard() }
    }

    IpcHandler {
        target: "tasks"
        function open(): void { taskManagerWindow.open() }
        function toggle(): void { taskManagerWindow.toggle() }
        function close(): void { taskManagerWindow.close() }
    }

    IpcHandler {
        target: "settingsapp"
        function open(): void { settingsWindow.open() }
        function toggle(): void { settingsWindow.toggle() }
        function close(): void { settingsWindow.close() }
    }

    // Floating overlay for surfaces
    Variants {
        model: Quickshell.screens
        SurfaceOverlay {}
    }

    // Material 3 Expressive Bar
    Bar {}
}
