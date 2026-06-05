# Architecture

## Overview

The SDC Kiosk App is a **single-file React application** designed for offline trade-show use. There is no server, no build pipeline, and no package manager involved at runtime. The entire app — UI, logic, data, and (in the self-contained build) all images and icons — lives in one HTML file.

```
SDC Kiosk App.html          ← source of truth
SDC Kiosk App - Self Contained.html  ← built output (bake_assets.py generates this)
```

---

## File Structure (inside the HTML)

The HTML file has four distinct sections:

### 1. CSS (`<style>` block, lines ~11–732)
All styles are in a single `<style>` block using CSS custom properties (variables). No external stylesheets.

Key design tokens defined in `:root`:
```css
--blue: #1574C4       /* SDC primary blue */
--navy: #061D39       /* dark navy */
--green: #74C415      /* accent green (called --yellow in legacy comments) */
--bg: #0a0e14         /* page background */
--panel / --panel-2 / --panel-3   /* card surface hierarchy */
```

The app renders at a **fixed 1920×1080 canvas** scaled to fit any screen via a CSS `scale()` transform. This means all sizing is in absolute px and renders identically on any screen size.

```js
// Scaling logic (lines ~742–749)
const s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
stage.style.setProperty("--scale", s);
```

### 2. React + Babel CDN (`<script>` tags, lines ~752–754)
```html
<script src="https://unpkg.com/react@18.3.1/umd/react.development.js">
<script src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.development.js">
<script src="https://unpkg.com/@babel/standalone@7.29.0/babel.min.js">
```
These are fetched from CDN on first load. In the self-contained build, these still load from CDN — only images/icons/logos are baked in, not JS libraries. Ensure the kiosk has internet access on first load, or cache these files locally.

> **Offline note:** If the kiosk has zero internet access, download these three JS files and change the `src` attributes to local paths.

### 3. Data (`window.SDC_DATA`, lines ~758–906)
All application content is stored as a plain JavaScript object on `window`:

```js
window.SDC_DATA = {
  company:       { name, tagline, phone, email, address, show, booth, venue },
  stats:         [ { value, label, sub } × 6 ],
  industries:    [ { id, name, icon, blurb, cases[] } × 7 ],
  capabilities:  [ { id, name, icon, desc, rate } × 9 ],
  caseStudies:   [ { id, title, industry, capability, blurb, technologies[],
                     rate, investment, leadTime, keyImpact, image, video } × 33 ],
  videos:        [ { id, caseId, title, industry, category, tags[], file } × 26 ],
  customerLogos: [ "filename.png" × 29 ],
}
```

**To update any content, edit only this object.** The React components read from it at render time.

### 4. React App (`<script type="text/babel">`, lines ~909–1692)

#### Asset helpers (lines ~940–943)
```js
const IMG_PATH  = p => `Image Files/${p}`;
const VID_PATH  = p => `Video Files/${p}`;
const ICON_PATH = p => `Icon Files/${p}`;
const LOGO_PATH = p => `Customer Logo Files/${p}`;
```
In the **self-contained build**, these are replaced by:
```js
const IMG_PATH  = p => window.SDC_ASSETS["Image Files/" + p]  || "Image Files/" + p;
// etc.
```
`window.SDC_ASSETS` is a `{ path: dataURI }` map injected by `bake_assets.py`.

#### Component tree
```
App
├── AttractScreen          (idle overlay, currently disabled — returns to Home after 90s instead)
├── Frame
│   ├── Header             (logo, back button, dot navigation)
│   ├── [Active Screen]    (swapped via route.name)
│   │   ├── HomeScreen
│   │   ├── CaseStudiesScreen → CaseStudyDetail
│   │   ├── IndustriesScreen  → IndustryDetail
│   │   ├── CapabilitiesScreen → CapabilityDetail
│   │   ├── VideosScreen      → VideoDetail
│   │   ├── NumbersScreen
│   │   └── ContactScreen
│   └── Footer             (email, phone, website)
└── HomeOverlay            (floating home button on non-home screens)
```

#### Routing
No router library. Routing is a `stack` state array of route objects:
```js
const [stack, setStack] = useState([{ name: "home" }]);
const route = stack[stack.length - 1];   // current screen
```
Navigate forward: `setStack(s => [...s, newRoute])`
Back: `setStack(s => s.slice(0, -1))`
Home: `setStack([{ name: "home" }])`

Route objects carry params:
```js
{ name: "case-study-detail", id: "ignition-coil" }
{ name: "industry-detail",   id: "automotive" }
{ name: "video-detail",      id: "v-wick" }
```

#### Idle reset
After **90 seconds** of no interaction, the app returns to the Home screen automatically:
```js
const IDLE_SEC = 90;
// timer runs every 1s, checks Date.now() - lastInteract.current
```

---

## Build Process (`bake_assets.py`)

The build script turns `SDC Kiosk App.html` → `SDC Kiosk App - Self Contained.html`:

1. **Scans** the HTML for all referenced asset filenames (images, icons, logos) via regex
2. **Compresses** each image using Pillow:
   - Max 1200×900 px (thumbnails are never displayed larger on the 1920px canvas)
   - JPEG quality 82 (typically 92–98% smaller than originals)
   - PNGs with transparency are kept as PNG; others converted to JPEG
3. **Base64-encodes** each compressed asset into a data URI
4. **Injects** `window.SDC_ASSETS = { "Image Files/Foo.jpg": "data:image/jpeg;base64,..." }` before the React CDN scripts
5. **Patches** the four helper functions to look up `SDC_ASSETS` first
6. **Patches** direct `src="Blue SDC Logo.png"` references in the HTML

**Output sizes:**
- Source HTML: ~104 KB
- Images (source): ~100 MB total
- Images (compressed): ~5 MB total
- Final self-contained HTML: ~22 MB

---

## Kiosk Launch Mechanism

```
LAUNCH KIOSK.vbs          ← user double-clicks this
  └── calls LAUNCH KIOSK.bat  (hidden, no command window)
        └── finds chrome.exe (or msedge.exe as fallback)
              └── launches with --kiosk --app="file:///..." flags
```

Chrome kiosk flags used:
| Flag | Effect |
|---|---|
| `--kiosk` | True fullscreen, no browser chrome |
| `--app="file:///..."` | Opens as an app window (no tab bar) |
| `--disable-pinch` | Disables pinch-to-zoom on touch screens |
| `--overscroll-history-navigation=0` | Disables swipe-back gesture |
| `--noerrdialogs` | Suppresses crash/error dialogs |
| `--hide-crash-restore-bubble` | No "Restore pages?" prompt on relaunch |
| `--check-for-update-interval=31536000` | Suppresses Chrome update nag (1 year) |

---

## Known Constraints

| Constraint | Reason |
|---|---|
| Videos not baked in | 5–6 GB total; browsers cannot parse multi-GB HTML |
| React loaded from CDN | Needs internet on first load (or swap to local files) |
| No video pre-loading | Videos stream from `Video Files/` folder at click time |
| Babel transpiles at runtime | ~1s startup delay; acceptable for kiosk use |
