# FloppyQR - Offline Web App Distribution Generator

## Overview

FloppyQR is a macOS app that packages web applications into two PNG files for offline distribution. It converts HTML/CSS/JS projects into a scannable QR bootloader + data disk.

## Output Files

| File | Format | Description |
|------|--------|-------------|
| `QRboot_<Name>_<Ver>_<Dev>_<ID>.png` | QR code | Scan → opens loader in browser |
| `Floppy_<Name>_<Ver>_<Dev>_<ID>.png` | PNG + zDAT | Contains compressed app data |

## How It Works

```
User's browser:
  Scan QRboot → data:text/html loader page
  → Select Floppy PNG → DecompressionStream('deflate') decompress
  → Extract index.html → document.write() → App runs
```

## CLI Usage

```bash
# Generate from single HTML
FloppyQR -i ./index.html -n "MyApp" -d "Developer" -c ./icon.png

# Generate from project directory (auto-inlines CSS/JS/images)
FloppyQR -i ./project-folder -n "Game" -v "2.0" -d "Qingdaomy" -s

# Output to specific directory
FloppyQR -i ./index.html -n "App" -o ./dist

# Launch GUI
FloppyQR
```

### CLI Options

| Flag | Description |
|------|-------------|
| `-i, --input <path>` | HTML file or project directory (required) |
| `-o, --output <dir>` | Output directory (default: current dir) |
| `-n, --name <name>` | App name (required) |
| `-v, --version <ver>` | Version (default: 1.0) |
| `-d, --developer <name>` | Developer name |
| `-c, --icon <path>` | Icon image (PNG/JPEG) |
| `-s, --strict` | Enable QRboot↔Floppy ID pairing |
| `-h, --help` | Show help |

## Data Format

### zDAT Chunk (custom PNG chunk)
- Chunk type: `zDAT` (ASCII)
- Payload layout: `[magic:4][ver:1][flags:1][appId:16][origLen:4][metaLen:2][metadata][compressed data]`
- Magic: `0xDA7A10DA`
- Compression: zlib (`0x78 0x9C` header + raw deflate + Adler32)
- Metadata: name, version, developer, 32×32 RGBA icon

### Multi-File Packing
```
[fileCount:4 BE] for each: [nameLen:2 BE][name UTF-8][dataLen:4 BE][data]
```
Single file: packed as `["index.html": htmlData]`

### Loader (embedded in QRboot)
- URL format: `data:text/html;charset=UTF-8,<encoded loader HTML>`
- Uses `DecompressionStream('deflate')` (requires Safari 16.4+ / Chrome 105+)
- QR version: V36-V40 depending on loader size (~2300 bytes)
- Supports strict appId pairing

## Integration Workflow for Agents

1. **Agent develops web app** → save to directory with `index.html`
2. **Agent calls FloppyQR CLI** or instructs user to:
   ```bash
   FloppyQR -i /path/to/project -n "AppName" -d "Developer"
   ```
3. **Distribution**: share `QRboot_*.png` + `Floppy_*.png`
4. **User**: scan QRboot → select Floppy PNG → app runs offline

## GUI Usage

When run without arguments, FloppyQR opens the native macOS UI:
1. Enter/paste HTML or choose a directory
2. Fill in metadata (name, version, developer, icon)
3. Click "Generate & Save" → choose output directory
4. Two PNG files are saved

## System Requirements

- **Generator**: macOS 12+
- **Loader**: Safari 16.4+ / Chrome 105+ / Firefox 112+ (requires `DecompressionStream` API)
- **Storage**: No server needed; fully offline
