#!/usr/bin/env python3
"""
FloppyQR CLI - Cross-platform offline web app packager

Usage:
  python floppyqr.py -i ./index.html -n "MyApp" -d "Developer"
  python floppyqr.py -i ./project-dir -n "Game" -v "2.0" -d "Qingdaomy" -c ./icon.png -s
  python floppyqr.py --help
"""
import os, sys, argparse, secrets, tempfile, shutil

def format_bytes(b):
    if b >= 1024*1024:
        return f"{b/1024/1024:.1f} MB"
    if b >= 1024:
        return f"{b/1024:.1f} KB"
    return f"{b} B"

def main():
    parser = argparse.ArgumentParser(
        description="FloppyQR - Offline Web App Distribution Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python floppyqr.py -i ./index.html -n "MyApp"
  python floppyqr.py -i ./project -n "Game" -d "Qingdaomy" -c ./icon.png -s
  python floppyqr.py -i ./project -n "App" -o ./output
        """
    )
    parser.add_argument('-i', '--input', required=True, help='HTML file or project directory')
    parser.add_argument('-o', '--output', default=None, help='Output directory (default: current)')
    parser.add_argument('-n', '--name', default='App', help='App name (required)')
    parser.add_argument('-v', '--version', default='1.0', help='Version (default: 1.0)')
    parser.add_argument('-d', '--developer', default='', help='Developer name')
    parser.add_argument('-c', '--icon', default=None, help='Icon image path (PNG/JPEG)')
    parser.add_argument('-s', '--strict', action='store_true', help='Enable QRboot↔Floppy ID pairing')
    parser.add_argument('--no-logo', action='store_true', help='Skip logo on Floppy PNG')

    args = parser.parse_args()
    input_path = os.path.abspath(os.path.expanduser(args.input))
    output_dir = os.path.abspath(os.path.expanduser(args.output)) if args.output else os.getcwd()
    os.makedirs(output_dir, exist_ok=True)

    # ── 1. Read HTML ──
    if os.path.isdir(input_path):
        print(f"📁 扫描目录: {os.path.basename(input_path)}")
        from generate import bundle_directory
        html = bundle_directory(input_path)
        print(f"   内联完成: {len(html.encode())} 字节")
    else:
        with open(input_path, 'r', encoding='utf-8') as f:
            html = f.read()
        print(f"📄 读取 HTML: {len(html.encode())} 字节")

    html_data = html.encode('utf-8')

    # ── 2. Process icon ──
    icon_rgba = None
    if args.icon:
        icon_path = os.path.abspath(os.path.expanduser(args.icon))
        if os.path.exists(icon_path):
            from generate import process_icon
            icon_rgba = process_icon(icon_path)
            print(f"🖼️  图标: {os.path.basename(icon_path)}")
        else:
            print(f"⚠️  图标不存在: {icon_path}")

    # ── 3. Build payload ──
    print("🔨 构建数据...")
    app_id_hex = secrets.token_hex(16)
    from generate import build_payload, create_floppy_png, generate_loader_html, generate_qrboot
    payload = build_payload(html_data, args.name, app_id_hex, args.strict, icon_rgba)
    compressed_size = len(payload) - (28 + 4132)

    # ── 4. Create Floppy PNG ──
    print("🖼️  生成 Floppy PNG...")
    logo_path = args.icon if not args.no_logo else None
    png_data = create_floppy_png(payload, logo_path=logo_path)

    # ── 5. Generate QRboot ──
    print("📱 生成 QRboot...")
    loader_html = generate_loader_html(app_id_hex, args.strict)
    qr_png = generate_qrboot(loader_html)

    # ── 6. Write files ──
    tag = args.name.replace('/', '_') or f"app_{app_id_hex[:8]}"
    ver = args.version.replace('/', '_')
    dev = args.developer.replace('/', '_') if args.developer else "unknown"
    base = f"{tag}_{ver}_{dev}_{app_id_hex[:8]}"

    floppy_path = os.path.join(output_dir, f"Floppy_{base}.png")
    qr_path = os.path.join(output_dir, f"QRboot_{base}.png")

    with open(floppy_path, 'wb') as f:
        f.write(png_data)
    with open(qr_path, 'wb') as f:
        f.write(qr_png)

    # ── 7. Stats ──
    print()
    print("✅ 生成成功!")
    print(f"   📄 HTML: {format_bytes(len(html_data))} → {format_bytes(compressed_size)} (zlib)")
    print(f"   🖼️  Floppy: {format_bytes(len(png_data))}")
    print(f"   📱 QRboot: {format_bytes(len(qr_png))}")
    print(f"   📍 输出目录: {output_dir}")
    print(f"   🔗 QRboot_{base}.png")
    print(f"   🔗 Floppy_{base}.png")

if __name__ == '__main__':
    main()
