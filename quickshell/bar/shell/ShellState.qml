pragma Singleton
import QtQuick
import Quickshell
import "root:/services"

// ShellState — єдиний стан оболочки (поверхні, панелі, діалоги).
// Доступний з будь-якого компонента через: import "root:/shell" -> ShellState.*
Singleton {
    id: root

    property string activeSurface: "idle"
    property string activeMonitor: ""

    signal openDashboardRequested(string monitor)
    signal toggleDashboardRequested(string monitor)
    signal closeDashboardRequested()

    signal openSettingsRequested()
    signal toggleSettingsRequested()
    signal closeSettingsRequested()

    signal openTasksRequested()
    signal toggleTasksRequested()
    signal closeTasksRequested()

    // монітор, на якому відкривати: явний (клік по бару) → інакше той, що у фокусі (хоткей/IPC)
    function resolveMonitor(monitor) { return monitor || MangoService.focusedMonitor }

    function openSurface(surface, monitor) {
        activeMonitor = resolveMonitor(monitor)
        activeSurface = surface
    }

    function toggleSurface(surface, monitor) {
        if (activeSurface === surface) {
            activeSurface = "idle"
            activeMonitor = ""
        } else {
            openSurface(surface, monitor)
        }
    }

    function closeSurfaces() {
        activeSurface = "idle"
        activeMonitor = ""
    }

    // morph — дашборд морфиться з бару/пілла (сигнали); інші режими — звичайна поверхня SurfaceOverlay
    readonly property bool _morph: BarConfig.openMode === "morph"
    function openDashboard(monitor) {
        if (_morph) openDashboardRequested(resolveMonitor(monitor)); else openSurface("dashboard", monitor)
    }
    function toggleDashboard(monitor) {
        if (_morph) toggleDashboardRequested(resolveMonitor(monitor)); else toggleSurface("dashboard", monitor)
    }
    function closeDashboard() {
        if (_morph) closeDashboardRequested(); else if (activeSurface === "dashboard") closeSurfaces()
    }

    function openSettings() { openSettingsRequested() }
    function toggleSettings() { toggleSettingsRequested() }
    function closeSettings() { closeSettingsRequested() }

    function openTasks() { openTasksRequested() }
    function toggleTasks() { toggleTasksRequested() }
    function closeTasks() { closeTasksRequested() }
}
