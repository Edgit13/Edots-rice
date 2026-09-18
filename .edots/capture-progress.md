# Capture — progress

## Phase 1 — Base integration (QuickSnip → Edots): ✅ DONE
- QuickSnip скопійовано в `quickshell/QuickSnip/`; бінди/install.sh/nix оновлені.
- Виправлення в процесі: Theme.qml (QtObject property), magick `\\(` escape, dimming.frag.qsb (curl з upstream).

## Phase 2 — Edots adaptive colors: ✅ DONE
- `Theme.qml` — читає `~/.config/quickshell/colors.json` (той самий файл, що пише wallcolors.py/matugen), watchChanges + fallback.
- Прив'язано: shell.qml (бейджі), RegionSelector (accent/tint/label/guides), WordOverlay (accent/surface/text/hover/pressed/lens/status), LensMode HTML (bg0/fg).
- Перевірено запуском: конфіг завантажується, OCR цикл працює (exit 0).

## Phase 3 — Screenshot: ✅ DONE (поточний стан)
- State machine в shell.qml: `menu` → (`action` | `monitor`) → `capture`.
- Запуск більше НЕ робить grim/region selection: спочатку головне Capture UI (Edots кольори).
- Region → Screenshot: кнопка тільки в меню → grim+scale (існуючий код) → RegionSelector →
  magick crop → `wl-copy --type image/png` → notify → повернення в меню (`resetToMenu()`), без Qt.quit.
- Monitor → Screenshot: список `Quickshell.screens` (name + resolution) → `grim -o <name>` →
  wl-copy image/png → notify → повернення в меню.
- Lifecycle: старий баг (автозакриття через ~1с) не відтворюється — селектор gated на appState === "capture".
  Після завершення дії — повернення в меню; вихід тільки через Esc (з menu/capture).
- Збереження: лише clipboard (існуюча поведінка QuickSnip), без filename/save-location UI.

### Файли Phase 3
- Змінено: `quickshell/QuickSnip/shell.qml` (state machine, CaptureButton, меню, 2 Process-и, resetToMenu).
- Не змінено: все інше (components/, modes/, shaders/, assets/, Theme.qml, settings.json, бінди).

## NEXT PHASE (Record / Lens) — не починати без команди
- Додати дії Region→Record (wf-recorder region), Monitor→Record, Region/Monitor→Lens.
- Меню вже має структуру source→action; додати кнопки дій у відповідні Column.

## Exact next step (наступна фаза)
1. Підтвердити Phase 3 у користувача (тест Region+Screenshot, Monitor+Screenshot на 2 моніторах).
2. За командою — реалізувати Record (wf-recorder) як наступну дію.
