# edot Browser: C++ / Chromium + Material 3

Двигун: C++20, Qt WebEngine (Chromium), Rust adblock-rust через C ABI. Інтерфейс: Qt Quick/QML у стилі Material 3.

## Збірка

```bash
sudo apt install build-essential cmake ninja-build cargo rustc curl \
  qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-webengine-dev qt6-webengine-dev-tools \
  libqt6sql6-sqlite qml6-module-qtquick qml6-module-qtquick-controls \
  qml6-module-qtquick-layouts qml6-module-qtquick-templates qml6-module-qtquick-window

cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
./build/edot-browser
```

`adblock` 0.13.x потребує свіжого Rust (cargo 1.85+, edition 2024). Якщо системний cargo старіший, ставте через rustup.
Без Rust (UI, CI): `-DEDOT_NO_RUST=ON`, фільтрація тоді вимкнена.

На Arch: `qt6-base qt6-declarative qt6-svg qt6-webengine`.

## Структура UI

| Файл | Призначення |
|---|---|
| `qml/Rail.qml` | Navigation Rail (Браузер / Закладки / Історія / Параметри) |
| `qml/Chrome.qml` | вкладки з фавіконами, навігація, адресний рядок, чіп дозволів, зірочка, прогрес |
| `qml/Pages.qml` | внутрішні сторінки в закругленій рамці |
| `qml/pages/ToolPage.qml` | список із пошуком (закладки, історія) |
| `qml/pages/SettingsPage.qml` | параметри |
| `qml/popups/*` | меню і дозволи сайту (окремі вікна `Qt::Popup`, не обрізаються) |
| `qml/components/*` | M3-компоненти: IconButton, M3Button, M3Switch, M3Select, M3Field, Segmented, Swatch, Card, M3Dialog |
| `src/theme.*` | схема ролей M3 (OKLCH), dark/light, colors.json |
| `src/app_settings.*` | `~/.config/edot-browser/settings.json` |
| `src/data_store.*` | закладки й історія, `~/.config/edot-browser/data.db` (той самий формат, що в Python-версії) |
| `src/image_providers.*` | `image://icon/...` (векторні іконки) і `image://tab/...` (фавіконки) |
| `src/filter_updater.*` | оновлення списків фільтрів у фоні |

## Тема

Параметри, Вигляд, Тема:
- **Dotfiles**: `~/.config/mango/colors.json`, інакше `~/Dotfiles/mango/colors.json`. Відсутні ролі M3 добудовуються з `primary`.
- **Темна / Світла**: повна схема M3 від акцентного кольору.

## Гарячі клавіші

Ctrl+T/W нова/закрити вкладку, Ctrl+L адреса, Ctrl+D закладка, Ctrl+R/F5 оновити, Ctrl+Shift+R без кешу,
Alt+←/→, Ctrl+Tab, Ctrl+H історія, Ctrl+Shift+O закладки, Ctrl+, параметри, Ctrl+= / Ctrl+- / Ctrl+0 масштаб.
