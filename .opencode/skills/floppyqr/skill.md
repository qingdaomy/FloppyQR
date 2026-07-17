# FloppyQR - Offline Web App Distribution Generator

## Overview
FloppyQR packages web apps into two PNG files for offline distribution.

| File | Purpose |
|------|---------|
| `QRboot_<name>_<ver>_<dev>_<id>.png` | QR code → opens loader in browser |
| `Floppy_<name>_<ver>_<dev>_<id>.png` | PNG + zDAT chunk with compressed app |

## Quick Install (macOS)

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
3. Agent runs FloppyQR CLI on user's project
4. Agent returns generated QRboot + Floppy PNGs

## For Cross-Platform (Linux/Windows)

Currently macOS only. For web-based generation, use the library components directly:
- Python: `PIL` + `zlib` + `qrcode` (see generator/generate.py)
- JavaScript: Available as npm package (coming soon)
