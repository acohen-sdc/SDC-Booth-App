# SDC Booth Kiosk App

Interactive trade-show kiosk for **Steven Douglas Corp. (SDC Automation)** — built for the **Automate 2026** show at McCormick Place, Chicago (Booth #26011).

The app is a single-page React application bundled as a self-contained HTML file. It runs entirely offline in a locked fullscreen browser window on the kiosk machine.

---

## Quick Start — Deploying to the Kiosk

Copy two things to the kiosk machine:

```
SDC Kiosk App - Self Contained.html   ← the deployable app (all assets baked in)
Video Files/                           ← MP4 videos (too large to bake into HTML)
```

Then on the kiosk:

1. Right-click `SETUP - Create Desktop Shortcut.ps1` → **Run with PowerShell**
2. Double-click **SDC Kiosk** on the desktop to launch
3. App opens in full-screen Chrome kiosk mode — no address bar, no tabs, no resizing

> **To exit the kiosk:** `Alt + F4` (staff only)

---

## Files in This Repo

| File / Folder | Purpose |
|---|---|
| `SDC Kiosk App.html` | **Source file** — all content and logic lives here |
| `SDC Kiosk App - Self Contained.html` | **Built/deployable** — source + images/icons/logos baked in as base64 |
| `LAUNCH KIOSK.vbs` | Silent launcher — double-click to start kiosk (no command window) |
| `LAUNCH KIOSK.bat` | Actual launch script — opens Chrome (or Edge) in kiosk mode |
| `SETUP - Create Desktop Shortcut.ps1` | Run once on kiosk to create a desktop shortcut |
| `Image Files/` | Case study photos (JPG/PNG) — source originals |
| `Icon Files/` | SVG icons for industries, capabilities, home cards |
| `Customer Logo Files/` | Customer logo PNGs for the scrolling logo bar |
| `Blue SDC Logo.png` | Primary SDC logo used in the app header and attract screen |
| `Blue SDC Logo Oval Only.png` | Oval-only version (reserved, not currently used in app) |
| `ARCHITECTURE.md` | Technical deep-dive into how the app is built |
| `CLAUDE.md` | Instructions for AI-assisted development with Claude |

### Not in the repo (too large / excluded by .gitignore)
| | |
|---|---|
| `Video Files/` | MP4 machine videos — ship on USB alongside the HTML |
| `*.pdf` | Brand guide, brochure, feedback docs |
| `*.xlsx` | Content template |

---

## Making Changes

### Editing content (case studies, stats, contact info, etc.)
All content is in the `window.SDC_DATA` object inside `SDC Kiosk App.html` starting around **line 758**. Edit that object — the app re-renders from it automatically.

### Rebuilding the self-contained file
After editing `SDC Kiosk App.html`, regenerate the deployable file:

```bash
python bake_assets.py
```

This compresses and base64-encodes all images, icons, and logos into a new `SDC Kiosk App - Self Contained.html`. Run time: ~30 seconds.

> Requires Python 3 + Pillow: `pip install Pillow`

### Adding a new case study
1. Add the image to `Image Files/`
2. Add a new entry to `caseStudies: [...]` in `SDC_DATA`
3. Add a video entry to `videos: [...]` if there's a matching MP4
4. Add the MP4 to `Video Files/`
5. Rebuild: `python bake_assets.py`

---

## Tech Stack

- **React 18** (loaded via CDN, no build toolchain required)
- **Babel Standalone** (JSX transpiled in-browser)
- **Vanilla CSS** (no framework)
- **Pillow** (Python, for image compression during the bake step only)

No `npm install`, no webpack, no bundler. The source file opens directly in any browser.
