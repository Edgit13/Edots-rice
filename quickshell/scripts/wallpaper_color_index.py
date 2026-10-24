#!/usr/bin/env python3
"""Build a color-category index for Edots wallpapers without changing image files.
Requires Pillow: python -m pip install --user pillow (or install python-pillow on Arch).
"""
from __future__ import annotations
import json, os, sys, tempfile, time, logging, traceback
from pathlib import Path
from collections import Counter
from PIL import Image, ImageStat

HOME = Path.home()
WALLPAPER_DIR = HOME / "Pictures" / "Wallpapers"
CACHE_DIR = HOME / ".cache" / "quickshell"
INDEX_FILE = CACHE_DIR / "wallpaper-colors.json"
STATUS_FILE = CACHE_DIR / "wallpaper-colors-status.json"
LOG_FILE = CACHE_DIR / "wallpaper-color-index.log"

def setup_logging() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8"), logging.StreamHandler(sys.stdout)],
        force=True,
    )

EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
CATEGORIES = ["Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Cyan", "Monochrome"]

def atomic_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name, dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.flush(); os.fsync(f.fileno())
        os.replace(tmp, path)
    finally:
        try: os.unlink(tmp)
        except FileNotFoundError: pass

def category_for(path: Path) -> str:
    started = time.monotonic()
    logging.info("START image=%s size=%s", path.name, path.stat().st_size)
    with Image.open(path) as im:
        im = im.convert("RGB")
        im.thumbnail((96, 96))
        pixels = list(im.getdata())
    if not pixels:
        logging.warning("EMPTY image=%s", path.name)
        return "Monochrome"
    # Average saturation/hue with circular hue averaging; ignores near-grey pixels.
    import colorsys, math
    hues, sats = [], []
    for r, g, b in pixels:
        h, s, _ = colorsys.rgb_to_hsv(r/255, g/255, b/255)
        sats.append(s)
        if s >= 0.18:
            hues.append(h)
    avg_sat = sum(sats) / len(sats)
    if not hues or avg_sat < 0.12:
        category = "Monochrome"
    else:
        x = sum(math.cos(2*math.pi*h) for h in hues)
        y = sum(math.sin(2*math.pi*h) for h in hues)
        hue = (math.atan2(y, x) / (2*math.pi)) % 1
        deg = hue * 360
        if deg < 15 or deg >= 345: category = "Red"
        elif deg < 40: category = "Orange"
        elif deg < 65: category = "Yellow"
        elif deg < 165: category = "Green"
        elif deg < 195: category = "Cyan"
        elif deg < 255: category = "Blue"
        elif deg < 290: category = "Purple"
        else: category = "Pink"
    logging.info("DONE image=%s category=%s elapsed=%.2fs", path.name, category, time.monotonic() - started)
    return category

def main() -> int:
    setup_logging()
    started = time.monotonic()
    logging.info("========== WALLPAPER SCAN START ==========")
    logging.info("Wallpaper directory: %s", WALLPAPER_DIR)
    logging.info("Index file: %s", INDEX_FILE)
    logging.info("Status file: %s", STATUS_FILE)
    logging.info("Log file: %s", LOG_FILE)
    if not WALLPAPER_DIR.is_dir():
        atomic_json(STATUS_FILE, {"state":"error", "message":f"Wallpaper folder not found: {WALLPAPER_DIR}", "current":0, "total":0})
        return 1
    files = sorted(p for p in WALLPAPER_DIR.iterdir() if p.is_file() and p.suffix.lower() in EXTS)
    logging.info("Found %d supported wallpaper files", len(files))
    if not files:
        atomic_json(INDEX_FILE, {"version":1, "directory":str(WALLPAPER_DIR), "generatedAt":int(time.time()), "items":{}, "categories":{}})
        atomic_json(STATUS_FILE, {"state":"done", "message":"No supported wallpapers found", "current":0, "total":0, "categories":{}})
        return 0
    items, counts = {}, Counter()
    atomic_json(STATUS_FILE, {"state":"running", "message":"Starting wallpaper analysis…", "current":0, "total":len(files), "categories":{}})
    for i, path in enumerate(files, 1):
        logging.info("PROGRESS %d/%d (%.1f%%)", i, len(files), i * 100 / len(files))
        try:
            cat = category_for(path)
            items[str(path)] = cat
            counts[cat] += 1
        except Exception:
            logging.exception("FAILED image=%s", path)
            items[str(path)] = "Other"
            counts["Other"] += 1
        if i == 1 or i % 5 == 0 or i == len(files):
            atomic_json(STATUS_FILE, {"state":"running", "message":path.name, "current":i, "total":len(files), "categories":dict(counts)})
    payload = {"version":1, "directory":str(WALLPAPER_DIR), "generatedAt":int(time.time()), "items":items, "categories":dict(counts)}
    atomic_json(INDEX_FILE, payload)
    atomic_json(STATUS_FILE, {"state":"done", "message":"Wallpaper categories are ready", "current":len(files), "total":len(files), "categories":dict(counts)})
    logging.info("========== SCAN COMPLETE: %d images in %.2fs; categories=%s ==========" , len(files), time.monotonic() - started, dict(counts))
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s", force=True)
        logging.exception("FATAL SCANNER ERROR: %s", exc)
        atomic_json(STATUS_FILE, {"state":"error", "message":str(exc), "current":0, "total":0})
        raise
