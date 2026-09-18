# Edots — M3 Redesign Progress (Bar + Capture, shared system)

## Архітектура
~/.config/quickshell/material/   ← ЄДИНИЙ M3-фундамент (M3.qml читає colors.json напряму)
  bar/material        → symlink на ../material
  QuickSnip/material  → symlink на ../material
M3.qml НЕ залежить від EdotsTheme/Colors singletons — працює в обох конфігах.

## ✅ Phase A — AUDIT (bar + capture)
## ✅ Phase B — FOUNDATION (shared M3 + 8 компонентів)
## ✅ Phase B-bar — CORE CHROME
  - bar/PillShell.qml: import root:/material; pill = M3 surfaceContainerLow →
    surfaceContainer на hover; рамки прибрано (glow = тонке 1px акцентне дихання);
    dividers → outlineVariant; TriggerIcon hover → M3.primary
  - bar/Clock.qml: повний rewrite (M3 monoLarge, onSurfaceVariant, showSeconds)
  - bar/Workspaces.qml: повний rewrite (active = primaryContainer, hover state layer,
    Config-driven count/spacing/size/radius/showNumbers; активний ws — локально,
    compositor IPC немає — чесна межа як в оригіналі)
## ⬜ Phase C-bar — SURFACES (Launcher/Wallpaper/Media/Mixer/Clipboard/Wifi/Link/Power/Settings)
## ⬜ Phase D-bar — SETTINGS UI (pages → M3)
## ⬜ Phase E-bar — TRAY/NET/AUDIO/BATTERY/MEDIA MODULES (hover-бар розширення)
## ⬜ Phase F-bar — MOTION/POLISH
## ⬜ Phase C..K — Capture (див. capture-progress.md)
