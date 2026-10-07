# edot Browser — C++/Chromium engine rewrite

This is a native C++ rewrite of the browser core/UI. Python/PySide6 is removed from the runtime.

## Architecture

- **C++20** application and UI
- **Qt 6 WebEngine** for the actual web engine; Qt WebEngine embeds Chromium.
- **Rust adblock-rust 0.13.3** as a native filter engine through a tiny C ABI. This understands EasyList/EasyPrivacy/uBlock-style network rules instead of doing naive substring checks.
- **Qt WebEngine profile** for persistent cookies/cache/storage.
- **NoScript-like per-domain permissions**: Trusted / Blocked / Default.

Qt documents that `QWebEngineUrlRequestInterceptor` intercepts requests before Chromium's networking stack and that `QWebEngineProfile` owns persistent storage/cache. See the official docs for those APIs.

## Ubuntu dependencies

Install Qt WebEngine development packages and Rust/Cargo, then configure/build:

```bash
sudo apt install build-essential cmake ninja-build qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-webengine-dev qt6-webengine-dev-tools libqt6sql6-sqlite cargo rustc curl

./scripts/update_filters.sh

cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
./build/edot-browser
```

If your distro uses different Qt package names, install the Qt 6 WebEngine development package provided by the distro.

## Permissions

Stored in:

`~/.config/edot-browser/permissions.json`

The shield button in the toolbar opens the current site's Trusted / Blocked / Default controls.

## Filter cache

`~/.cache/edot-browser/filters/`

Run `scripts/update_filters.sh` whenever you want to refresh the lists. The browser can start with the bundled bootstrap list even when the network is unavailable.

## Why C++ + Qt WebEngine

The project does not implement a browser engine from scratch. The heavy web engine is Chromium, while C++ is used for the application layer. This avoids the Python/PySide6 runtime overhead and gives a native application boundary around Chromium. Qt's WebEngine API is specifically designed for embedding Chromium-based web content.
