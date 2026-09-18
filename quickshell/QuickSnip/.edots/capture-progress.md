# Capture — Material 3 Redesign: Progress

## Phase A — AUDIT ✅ (completed)
- Застосунок: QuickSnip (Ronin-CK) + EdotsTheme (colors.json, live-watch) у ~/.config/quickshell/QuickSnip/
- УВАГА: у репо Capture немає (живе лише локально) — після редизайну запушити!
- Компоненти UI: shell.qml (root, workflow, mode-бейджі), components/RegionSelector.qml,
  components/WordOverlay.qml (word-OCR UI + toolbar + status pill + lens-кнопка),
  shaders/dimming (скомпільований, залишається), assets/lens-white.svg
- Логіка (backend, не чіпати): modes/{Lens,Ocr,Select}Mode.qml, components/Settings.qml, settings.json
- Колір: EdotsTheme.qml singleton (colors.json)
- Лайфцайкл-інваріанта: жодного авто-visible overlay; дії тільки з явного входу

## Phase B — FOUNDATION ✅ (completed)
material/:
- M3.qml — singleton: M3-ролі з EdotsTheme (primary=accent, surface=bg0..bg3,
  onSurface=fg, outline=grey1, error=red, контейнери через mix()), state layers,
  типографіка, spacing, radii, motion
- MaterialButton.qml (filled/tonal/outlined/text, icon, tooltip)
- MaterialIconButton.qml (standard/filled/tonal/outlined, selected)
- MaterialCard.qml (filled/outlined)
- MaterialSwitch.qml (M3 52x32)
- MaterialTextField.qml (outlined, label+placeholder)
- MaterialDialog.qml (scrim, rXL, title/supporting/actions)
- MaterialListItem.qml (icon/headline/supporting/trailing)
- MaterialSegmented.qml (M3 segmented buttons)
Install: покласти material/ у корінь QuickSnip (root:/material).

## Phase C — MAIN CAPTURE UI ⬜ (next)
Головне вікно: source (Region/Monitor — MaterialSegmented) + action (Screenshot/Record/Lens —
картки з іконкою/описом) + Material-кнопки. Застосувати в shell.qml/новому Launcher.

## Phase D — REGION/MONITOR SELECT ⬜
## Phase E — SCREENSHOT RESULT ⬜
## Phase F — RECORD UI ⬜
## Phase G — LENS/OCR UI ⬜ (WordOverlay → M3)
## Phase H — SETTINGS ⬜
## Phase I — DIALOGS/MENUS/STATES ⬜
## Phase J — POLISH ⬜
## Phase K — CLEANUP ⬜
