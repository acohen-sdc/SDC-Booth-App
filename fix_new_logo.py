"""
fix_new_logo.py — Run this on any new logo before adding it to customerLogos.

Usage:
    python fix_new_logo.py "Customer Logo Files/NewLogo.jpg"
    python fix_new_logo.py "Customer Logo Files/NewLogo.png"

What it does:
1. Converts JPG → PNG with transparent background (removes white/light background)
2. Detects if a colored rectangle background is present and removes it
3. Warns if the logo looks like a circular filled emblem (grey blob risk)
4. Saves the result as a transparent PNG ready for the kiosk

Rules for adding logos:
- ONLY add logos that come out with clear text/icon shapes on transparency
- If the script warns "BLOB RISK", skip this logo — it will look like a grey disc
- If unsure, check the file in an image viewer: it should show logo shapes, not filled rectangles
"""

import sys
import os
from PIL import Image
from collections import deque, Counter

def color_dist(c1, c2):
    return ((int(c1[0])-int(c2[0]))**2 + (int(c1[1])-int(c2[1]))**2 + (int(c1[2])-int(c2[2]))**2)**0.5

def detect_background_color(img, border_depth=6):
    """
    Sample the outermost border_depth pixels and find the dominant color.
    Only returns a color if it STRONGLY dominates (>85%) — meaning it's a uniform background.
    If the border has many different colors (logo elements touching edge), returns None.
    """
    px = img.load()
    w, h = img.size
    colors = Counter()
    total = 0
    for x in range(w):
        for y in range(border_depth):
            p = px[x, y]
            if p[3] > 100:
                colors[p[:3]] += 1
                total += 1
        for y in range(h - border_depth, h):
            p = px[x, y]
            if p[3] > 100:
                colors[p[:3]] += 1
                total += 1
    for y in range(h):
        for x in range(border_depth):
            p = px[x, y]
            if p[3] > 100:
                colors[p[:3]] += 1
                total += 1
        for x in range(w - border_depth, w):
            p = px[x, y]
            if p[3] > 100:
                colors[p[:3]] += 1
                total += 1
    if total < 20:
        return None  # border mostly transparent = no background
    top_color, top_count = colors.most_common(1)[0]
    dominance = top_count / total
    if dominance < 0.80:
        return None  # border has mixed colors = logo touching edge, not a background
    return top_color

def remove_background(img, bg_color, tolerance=40):
    """Flood fill from transparent border outward, removing bg_color pixels."""
    px = img.load()
    w, h = img.size

    def is_removable(p):
        if p[3] < 20:
            return True  # already transparent / semi-transparent edge
        return color_dist(p[:3], bg_color) < tolerance

    visited = set()
    q = deque()
    for x in range(w):
        for y in [0, h-1]:
            if is_removable(px[x, y]) and (x, y) not in visited:
                visited.add((x, y))
                q.append((x, y))
    for y in range(h):
        for x in [0, w-1]:
            if is_removable(px[x, y]) and (x, y) not in visited:
                visited.add((x, y))
                q.append((x, y))

    removed = 0
    while q:
        x, y = q.popleft()
        p = px[x, y]
        if p[3] > 0 and is_removable(p):
            px[x, y] = (p[0], p[1], p[2], 0)
            removed += 1
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited and is_removable(px[nx, ny]):
                visited.add((nx, ny))
                q.append((nx, ny))
    return removed

def check_blob_risk(img):
    """
    Returns (fill_ratio, is_blob).
    Logos where a single connected opaque region fills >50% of the bounding box
    AND >40% of the whole image are circular filled emblems — they show as grey blobs.
    """
    px = img.load()
    w, h = img.size
    total = w * h
    opaque_coords = [(x, y) for x in range(w) for y in range(h) if px[x, y][3] > 50]
    if not opaque_coords:
        return 0, False
    opaque_set = set(opaque_coords)
    visited = set()
    max_comp = 0
    for start in opaque_coords:
        if start in visited:
            continue
        q = deque([start])
        visited.add(start)
        size = 0
        while q:
            x, y = q.popleft()
            size += 1
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nb = (x + dx, y + dy)
                if nb in opaque_set and nb not in visited:
                    visited.add(nb)
                    q.append(nb)
        max_comp = max(max_comp, size)
    pct = max_comp / total * 100
    is_blob = pct > 40 and (len(opaque_coords) / total) > 0.35
    return pct, is_blob


def process_logo(filepath):
    print(f"\nProcessing: {filepath}")
    base, ext = os.path.splitext(filepath)
    out_path = base + ".png"

    # Load image
    img = Image.open(filepath).convert("RGBA")
    w, h = img.size
    print(f"  Size: {w}x{h}, mode: {Image.open(filepath).mode}")

    # Step 1: Remove white background (for JPGs or PNGs with white bg)
    px = img.load()
    total = w * h
    opaque_before = sum(1 for x in range(w) for y in range(h) if px[x, y][3] > 50)

    # Simple white background removal: if corners are opaque and white-ish, flood fill
    corners = [px[0, 0], px[w-1, 0], px[0, h-1], px[w-1, h-1]]
    white_corners = [c for c in corners if c[3] > 100 and c[0] > 220 and c[1] > 220 and c[2] > 220]
    if len(white_corners) >= 2:
        print(f"  Detected white background (corners opaque+white) — removing...")
        removed = remove_background(img, (255, 255, 255), tolerance=30)
        print(f"  Removed {removed} white background pixels")

    # Step 2: Detect other colored rectangular background
    bg_color = detect_background_color(img, border_depth=6)
    if bg_color:
        brightness = sum(bg_color) / 3
        print(f"  Detected uniform background: {bg_color} (brightness={brightness:.0f}) — removing...")
        removed = remove_background(img, bg_color, tolerance=40)
        print(f"  Removed {removed} background pixels")
    else:
        print(f"  No uniform rectangular background detected (border has mixed/transparent pixels — good)")

    # Step 3: Check opaque pixel count
    px = img.load()
    opaque_after = sum(1 for x in range(w) for y in range(h) if px[x, y][3] > 50)
    pct_after = opaque_after / total * 100
    print(f"  Opacity: {opaque_before/total*100:.1f}% → {pct_after:.1f}%")

    if pct_after < 2:
        print(f"  !! WARNING: Logo is nearly empty ({pct_after:.1f}% opaque).")
        print(f"     The flood fill likely removed the logo itself (brand color = bg color).")
        print(f"     DO NOT USE this file. Restore the original and add manually to customerLogos WITHOUT running this script.")
        return

    # Step 4: Check blob risk
    max_comp_pct, is_blob = check_blob_risk(img)
    if is_blob:
        print(f"  !! BLOB RISK: largest connected region = {max_comp_pct:.1f}% of image.")
        print(f"     This logo is likely a circular filled emblem (like GE or NASA meatball).")
        print(f"     It will appear as a grey disc/blob in the kiosk. DO NOT add to customerLogos.")
        print(f"     Ask the company for a transparent text-only version of their logo.")
        return

    # Save result
    img.save(out_path)
    if out_path != filepath:
        print(f"  Saved as: {out_path}")
    else:
        print(f"  Updated: {out_path}")
    print(f"  OK — ready to add to customerLogos list in SDC Kiosk App.html")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fix_new_logo.py <path_to_logo_file>")
        print("Example: python fix_new_logo.py \"Customer Logo Files/NewClient.jpg\"")
        sys.exit(1)
    process_logo(sys.argv[1])
