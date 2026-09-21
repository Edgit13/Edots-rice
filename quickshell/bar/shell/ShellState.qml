pragma Singleton
import QtQuick
import Quickshell

// ShellState — єдиний стан оболочки (поверхні, панелі, діалоги).
// Доступний з будь-якого компонента через: import "root:/shell" -> ShellState.*
Singleton {
    id: root

    property string activeSurface: "idle"

    signal openDashboardRequested()
    signal toggleDashboardRequested()
    signal closeDashboardRequested()

    signal openSettingsRequested()
    signal toggleSettingsRequested()
    signal closeSettingsRequested()

    signal openTasksRequested()
    signal toggleTasksRequested()
    signal closeTasksRequested()

    function openSurface(surface) {
        activeSurface = surface
    }

    function toggleSurface(surface) {
        if (activeSurface === surface) activeSurface = "idle"
        else openSurface(surface)
    }

    function closeSurfaces() {
        activeSurface = "idle"
    }

    function openDashboard() { openDashboardRequested() }
    function toggleDashboard() { toggleDashboardRequested() }
    function closeDashboard() { closeDashboardRequested() }

    function openSettings() { openSettingsRequested() }
    function toggleSettings() { toggleSettingsRequested() }
    function closeSettings() { closeSettingsRequested() }

    function openTasks() { openTasksRequested() }
    function toggleTasks() { toggleTasksRequested() }
    function closeTasks() { closeTasksRequested() }
}
