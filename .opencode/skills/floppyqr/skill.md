# FloppyQR - Offline Web App Distribution Generator

## Overview
FloppyQR packages web apps into two PNG files for offline distribution.

| File | Purpose |
|------|---------|
| `QRboot_<name>_<ver>_<dev>_<id>.png` | QR code → opens loader in browser |
| `Floppy_<name>_<ver>_<dev>_<id>.png` | PNG + zDAT chunk with compressed app |

## Quick Install

**跨平台（Python，推荐 Agent 使用）**
```bash
pip install Pillow qrcode
python generator/floppyqr.py -i ./myapp -n "MyApp" -d "Developer"
```

**macOS DMG（手动安装）**

**方式一：DMG（手动安装）**
```bash
curl -L -o ~/Downloads/FloppyQR.dmg https://github.com/qingdaomy/FloppyQR/releases/latest/download/FloppyQR_macOS.dmg
open ~/Downloads/FloppyQR.dmg
# 拖 FloppyQR.app 到 Applications 文件夹
```

**方式二：CLI 工具（Agent 自动使用）**
```bash
curl -L -o FloppyQR.zip https://github.com/qingdaomy/FloppyQR/releases/latest/download/FloppyQR_macOS.zip
unzip FloppyQR.zip
# Run CLI tool
FloppyQR.app/Contents/MacOS/FloppyQR -i ./index.html -n "MyApp"
# Or add to PATH
sudo ln -s "$(pwd)/FloppyQR.app/Contents/MacOS/FloppyQR" /usr/local/bin/FloppyQR
```

## CLI Usage (No Xcode needed)

```bash
FloppyQR -i ./index.html -n "MyApp"
FloppyQR -i ./project-folder -n "Game" -v "2.0" -d "Developer" -c ./icon.png -s
FloppyQR -i ./index.html -n "App" -o ./output-dir
FloppyQR                        # Launch GUI
```

### Options

| Flag | Description |
|------|-------------|
| `-i, --input <path>` | HTML file or project directory (required) |
| `-o, --output <dir>` | Output directory (default: current) |
| `-n, --name <name>` | App name (required) |
| `-v, --version <ver>` | Version (default: 1.0) |
| `-d, --developer <name>` | Developer name |
| `-c, --icon <path>` | Icon image (PNG/JPEG) |
| `-s, --strict` | Enable QRboot↔Floppy ID pairing |
| `-h, --help` | Show help |

## How It Works

```
User scans QRboot → data:text/html loader → select Floppy PNG
→ DecompressionStream('deflate') decompress → render index.html → offline app runs
```

### Architecture (v2)

| Component | Source | Scans Chunk | Action |
|-----------|--------|-------------|--------|
| **Qrboot** | `LoaderHTMLTemplate.swift` → QR code | `zLDR` only | Extract FloppyQR.html → `document.write` transform |
| **FloppyQR** | `FloppyQRHTMLTemplate.swift` → zLDR chunk | `zDAT` only | Extract app HTML → render via `location.href` |

**Qrboot**: One-time setup gateway. On first `FQ_loader` detection, auto-transforms into FloppyQR.html. User bookmarks the same data: URI.

**FloppyQR**: Permanent launcher. Manages app history via `localStorage` (`FQ_v1` key). 64×64 icon grid (4 per row), click icon to run.

### Critical Safari Compatibility Rules

1. **File picker**: MUST use `<label for=f>` wrapping the floppy visual with `pointer-events:none` on the inner div. `<label>` is the only reliable way to trigger file input on iOS. `onclick="f.click()"` or transparent `<input>` are unreliable on iOS data: URI.

2. **File reading**: Use `document.getElementById('f').addEventListener('change', function(){})` (regular function, NOT async). `FileReader` or `f.arrayBuffer()` with `.then()` chains inside. NO `async/await` — mobile Safari loses user activation after awaits.

3. **`accept=.png`**: Restricts to PNG files. Mobile OS shows "Browse" (Files) option for file selection.

4. **Page transform**: NEVER use `document.write()` or `location.reload()`. Mobile Safari blocks these in async contexts. Always use `location.href = URL.createObjectURL(new Blob([html], {type:'text/html'}))`.

5. **No persistent storage**: Safari blocks localStorage/sessionStorage/indexedDB/cookies on `data:` URI (null origin). `window.name` persists within same-tab navigation. For multi-app cache, store in `window.name` as `{c: [appArray]}`.

6. **LED feedback**: Green=ready, Breathing=processing, Red=error (no timeout clear). No change = handler not firing (usually file picker issue).



### Data Format
- **zDAT chunk**: `[magic:4][ver:1][flags:1][appId:16][origLen:4][metaLen:2][metadata][zlib data]`
- **Magic**: `0xDA7A10DA`
- **Compression**: zlib (`0x78 0x9C` header + raw deflate + Adler32)
- **Loader**: encoded as `data:text/html;charset=UTF-8,<loader HTML>` (~2.3KB)

### System Requirements
- **Generator**: macOS 12+ (pre-built binary, no Xcode needed)
- **Loader**: Safari 16.4+ / Chrome 105+ / Firefox 112+ (requires `DecompressionStream`)
- **Storage**: Fully offline, no server needed

## AI Agent Workflow

1. User asks: "Package my web app with FloppyQR"
2. Agent downloads FloppyQR (if not present):
   ```bash
   if ! command -v FloppyQR &> /dev/null; then
     curl -L -o /tmp/FloppyQR.zip https://github.com/qingdaomy/FloppyQR/releases/latest/download/FloppyQR_macOS.zip
     unzip -o /tmp/FloppyQR.zip -d /tmp/FloppyQR
     chmod +x /tmp/FloppyQR/FloppyQR.app/Contents/MacOS/FloppyQR
   fi
   ```
3. **Agent runs mobile compatibility pre-flight check** on user's project:
   ```bash
   INPUT="$1"  # user's project directory or HTML file
   
   # Find the main HTML file
   if [ -d "$INPUT" ]; then
     HTML_FILE="$INPUT/index.html"
   else
     HTML_FILE="$INPUT"
   fi
   
   if [ ! -f "$HTML_FILE" ]; then
     echo "❌ No index.html found"
     exit 1
   fi
   
   # Check viewport meta
   HAS_VIEWPORT=$(grep -c "name=.viewport" "$HTML_FILE" 2>/dev/null || echo 0)
   
   # Check @media queries in CSS files
   MEDIA_COUNT=0
   CSS_FILES=$(find "$(dirname "$HTML_FILE")" -name "*.css" 2>/dev/null)
   for CSS in $CSS_FILES; do
     COUNT=$(grep -c "@media" "$CSS" 2>/dev/null || echo 0)
     MEDIA_COUNT=$((MEDIA_COUNT + COUNT))
   done
   
   # Check CSS framework (Bootstrap/Tailwind)
   HAS_FRAMEWORK=$(grep -ic "bootstrap\|tailwind\|foundation\|bulma" "$HTML_FILE" 2>/dev/null || echo 0)
   
   # Count fixed-width elements in CSS
   FIXED_WIDTHS=0
   for CSS in $CSS_FILES; do
     COUNT=$(grep -cP "min-width\s*:\s*\d+px|width\s*:\s*\d{3,}px" "$CSS" 2>/dev/null || echo 0)
     FIXED_WIDTHS=$((FIXED_WIDTHS + COUNT))
   done
   
   # Score calculation
   SCORE=0
   [ "$HAS_VIEWPORT" -gt 0 ] && SCORE=$((SCORE + 40))
   [ "$MEDIA_COUNT" -gt 0 ] && SCORE=$((SCORE + 30))
   [ "$HAS_FRAMEWORK" -gt 0 ] && SCORE=$((SCORE + 20))
   [ "$FIXED_WIDTHS" -gt 20 ] && SCORE=$((SCORE - 10))
   
   echo "📱 Mobile Compatibility Score: $SCORE/100"
   [ "$HAS_VIEWPORT" -gt 0 ] && echo "  ✅ viewport meta: present" || echo "  ❌ viewport meta: MISSING (severe)"
   [ "$MEDIA_COUNT" -gt 0 ] && echo "  ✅ @media queries: $MEDIA_COUNT found" || echo "  ❌ @media queries: NONE (not responsive)"
   [ "$HAS_FRAMEWORK" -gt 0 ] && echo "  ✅ CSS framework detected" || echo "  ⚠️ No CSS framework detected"
   echo "  📏 Fixed-width elements: $FIXED_WIDTHS"
   
   if [ "$SCORE" -lt 50 ]; then
     echo ""
     echo "⚠️  This app is NOT mobile-responsive. The Floppy PNG will work on desktop"
     echo "   but the app may display incorrectly on mobile phones."
     echo "   Issues likely: nav overflow, sidebar overlap, popups off-screen."
     echo ""
     echo "   Continue packaging anyway? [y/N]"
     read -r CONFIRM
     if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
       echo "❌ Packaging cancelled. Please add responsive CSS before retrying."
       exit 1
     fi
   elif [ "$SCORE" -lt 80 ]; then
     echo ""
     echo "ℹ️  Partially mobile-responsive. Test on a real device before distributing."
   fi
   ```
4. **If user confirms**, Agent runs FloppyQR CLI on user's project:
   ```bash
   FloppyQR.app/Contents/MacOS/FloppyQR -i "$INPUT" -n "$APP_NAME" -o "$OUTPUT_DIR"
   ```
5. Agent returns generated QRboot + Floppy PNGs
6. **If app was not mobile-ready**: remind user that the app may not display correctly on mobile

## Cross-Platform (Linux/Windows/macOS)

Python CLI is available and works on all platforms:

```bash
pip install Pillow qrcode
python generator/floppyqr.py -i ./myapp -n "MyApp"
```

Or use the library directly in Python scripts:
```python
from generator.generate import bundle_directory, build_payload, create_floppy_png, generate_qrboot
```
