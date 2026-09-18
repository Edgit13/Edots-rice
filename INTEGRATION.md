# QuickSnip → Edots integration

Мета цього етапу: **QuickSnip functionality + Edots automatic colors**. Нічого більше.
Змінено ТІЛЬКИ кольори. Архітектура, workflow, lifecycle, UI — upstream.

## Структура (що куди в репозиторії Edots)

```
quickshell/QuickSnip/        ← НОВЕ: повна копія QuickSnip (Ronin-CK/QuickSnip)
├── shell.qml                ← entry point; +Theme, біндінги кольорів, бейджі
├── Theme.qml                ← НОВЕ: читає ~/.config/quickshell/colors.json (watchChanges)
├── settings.json            ← Edots-дефолти (newtab, firefox, target_lang=uk)
├── components/
│   ├── Settings.qml         ← verbatim upstream
│   ├── RegionSelector.qml   ← кольори через property (accent/tint/label)
│   └── WordOverlay.qml      ← кольори через property (accent/surface/text/…)
├── modes/
│   ├── SelectMode.qml       ← verbatim upstream (немає кольорів)
│   ├── OcrMode.qml          ← verbatim upstream (немає кольорів)
│   └── LensMode.qml         ← HTML-сторінка Lens: bg0/fg з теми
├── shaders/                 ← verbatim upstream (dimming — нейтральний чорний)
└── assets/lens-white.svg    ← verbatim upstream

mango/binds.conf             ← SUPER+U / SUPER+SHIFT+U → QuickSnip (rishot видалено)
mango/scripts/lens.sh        ← deprecated-wrapper → QuickSnip
install.sh                   ← −rishot, +grim +tesseract +tesseract-data-eng
nix/home.nix                 ← +xdg.configFile "quickshell/QuickSnip"
nix/rice.nix                 ← БЕЗ змін (capture-залежності вже повні)
```

## Як працюють кольори

- `mango/scripts/wallcolors.py` (matugen) вже пише `~/.config/quickshell/colors.json`
  (ключі: bg0–bg4, fg, accent, grey1, grey2, …) — той самий файл, що використовує бар.
- `quickshell/QuickSnip/Theme.qml` читає його через `FileView { watchChanges: true }`:
  перегенерація палітри підхоплюється без перезапуску capture (на наступному запуску;
  живий інстант уже перехопить watchChanges, але QuickSnip одноразовий).
- Хардкод Catppuccin `#cba6f7` замінено на `theme.accent`; фони тулбару/pill → bg1/bg2;
  тексти → fg; hover/grey → grey1/grey2 з alpha.
- Якщо colors.json відсутній — fallback на дефолтну Edots-палітру.

## Встановлення (Arch)

1. Пакети: `sudo pacman -S --needed grim tesseract tesseract-data-eng`
   (ukr-дані опційно: `tesseract-data-ukr`, тоді `"OCR": {"language": "eng+ukr"}`).
2. Скопіюй `quickshell/QuickSnip/` у репозиторій, застосуй правки до
   `mango/binds.conf`, `mango/scripts/lens.sh`, `install.sh`.
3. `./sync.sh` (лінкує весь `quickshell/` у `~/.config/quickshell` — окремих кроків не треба).
4. NixOS: додай рядок у `nix/home.nix` (див. файл тут) → `nixos-rebuild switch`.
   `nix/rice.nix` вже містить grim/slurp/imagemagick/wl-clipboard/tesseract(eng+ukr+rus).

## Запуск / бінди

- `SUPER+U` → повний цикл QuickSnip: region → (OCR words | direct `d` | raw `r` | single `s`)
  → toolbar (Search/Copy/Translate/All) + Lens-кнопка.
- `SUPER+SHIFT+U` → те саме (старий lens.sh тепер wrapper).
- Шорткати всередині: Esc — вихід, Enter/Ctrl+C — copy, Ctrl+A — all, d/r/s — режими OCR.
- Workflow повністю upstream: temp-файли в `Quickshell.cachePath` з cleanup; clipboard
  через wl-copy; Lens — base64→temp HTML→xdg-open.

## MangoWC-сумісність

QuickSnip використовує лише generic Wayland: grim, wlr-layer-shell, wl-clipboard,
xdg-open, magick, tesseract. Hyprland-only API немає — MangoWC (wlroots) сумісний.
`wlrctl`/`wtype` потрібні лише для `open_in: "sidebar"` (ми використовуємо `newtab`).

## Що НЕ змінено (за завданням)

- Layout, кнопки, OCR UI, Lens UI, selection UI, smart-action роутинг, lifecycle,
  temp-file behavior, TSV-парсинг, scale-детект — все verbatim upstream.
- Recording: у QuickSnip немає; `wf-recorder` лишається встановленим (без бінду),
  при потребі додамо окремим етапом.

## Тест-план

1. `qs -p ~/.config/quickshell/QuickSnip/shell.qml` — має з'явитися dimming+курсор.
2. Drag-регіон → OCR words → hover/click/Copy → текст у wl-paste.
3. `d` → direct OCR → notify + clipboard.
4. Lens-кнопка → відкривається Google Lens з кропом.
5. Зміна шпалери (wallcolors.py) → новий запуск capture показує нові кольори.
6. Multi-monitor: вікно на кожному екрані, grim `-o <screen>`.

## Відомі нюанси

- `wallcolors.py` робить `killall quickshell` — вб'є й запущений capture-інстант.
  QuickSnip одноразовий, тож це безпечно; наступний запуск отримає нові кольори.
- `settings.json` QuickSnip лежить у `~/.config/quickshell/QuickSnip/settings.json`
  (репо-файл через symlink — sync.sh лінкує цілий каталог).
