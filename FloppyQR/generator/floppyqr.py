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

    # ── 4. Create Floppy PNG with zLDR (FloppyQR loader) ──
    print("🖼️  生成 Floppy PNG...")
    logo_path = args.icon if not args.no_logo else None
    # Generate FloppyQR HTML for zLDR chunk
    loader_name = args.developer or 'App'
    zldr_html = f"""<!DOCTYPE html><html><meta charset=UTF-8><meta name=viewport content="width=device-width,initial-scale=1"><title>FloppyQR</title><style>
*{{margin:0;padding:0}}body{{background:#f8fafc;font-family:sans-serif;color:#334155;padding:20px;max-width:500px;margin:0 auto}}h1{{font-size:20px;color:#1e293b;text-align:center;margin:16px 0}}#b{{width:192px;height:64px;background:#cbd5e1;border-radius:14px;display:flex;align-items:center;cursor:pointer;margin:0 auto}}#s{{margin-left:20px;width:106px;height:22px;background:#dce3ec;border-radius:4px}}#l{{width:22px;height:22px;border-radius:50%;background:#22c55e;margin-left:auto;margin-right:20px;transition:all .3s}}.b{{animation:c 1.5s infinite}}@keyframes c{{50%{{opacity:.3}}}}.r{{background:#ef4444!important}}.y{{background:#eab308!important}}h2{{font-size:16px;margin:20px 0 10px;color:#475569}}.i{{background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:10px 14px;display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;gap:8px}}.i .n{{font-size:14px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}}.i .d{{font-size:11px;color:#94a3b8}}.i button{{padding:5px 14px;border:none;border-radius:8px;font-size:12px;font-weight:600;cursor:pointer;flex-shrink:0}}.rn{{background:#22c55e;color:#fff}}.dl{{background:#fee2e2;color:#dc2626}}.emp{{text-align:center;color:#94a3b8;font-size:14px;padding:20px}}.ft{{text-align:center;color:#94a3b8;font-size:12px;margin-top:20px}}
</style>
<h1>\\U0001f4be FloppyQR</h1>
<div id=b onclick="document.getElementById('f').click()"><div id=s></div><div id=l></div></div>
<p style=text-align:center;color:#94a3b8;font-size:13px;margin:8px 0>\\u9009\\u62e9 Floppy PNG</p>
<h2>\\u5386\\u53f2\\u5e94\\u7528</h2>
<div id=lst><div class=emp>\\u6682\\u65e0\\u5386\\u53f2</div></div>
<p class=ft>FloppyQR</p>
<input type=file accept=image/png id=f style=display:none>
<script>
var M=0xDA7A10DA,g=document.getElementById('l'),K='FloppyQR';
function C(){{return JSON.parse(localStorage.getItem(K)||'[]')}}
function S(a){{localStorage.setItem(K,JSON.stringify(a))}}
function R(){{var a=C(),h=document.getElementById('lst');h.innerHTML='';
if(!a.length){{h.innerHTML='<div class=emp>\\u6682\\u65e0\\u5386\\u53f2</div>';return}}
a.slice().reverse().forEach(function(x){{
var d=document.createElement('div');d.className='i';
var n=document.createElement('div');n.className='n';n.textContent=x.n;
var dt=document.createElement('div');dt.className='d';dt.textContent=new Date(x.t).toLocaleDateString();
var nb=document.createElement('button');nb.className='rn';nb.textContent='\\u8fd0\\u884c';
nb.onclick=function(){{var aa=C(),xx=aa.find(function(v){{return v.id==x.id}});if(xx){{document.open();document.write(xx.h);document.close()}}}};
var db=document.createElement('button');db.className='dl';db.textContent='\\u2715';
db.onclick=function(){{var aa=C();aa=aa.filter(function(v){{return v.id!=x.id}});S(aa);R()}};
var l=document.createElement('div');l.appendChild(n);l.appendChild(dt);
d.appendChild(l);d.appendChild(nb);d.appendChild(db);h.appendChild(d)}})}}
document.getElementById('f').onchange=async function(){{var f=this.files[0];if(!f)return;g.className='b';
try{{
var v=new DataView(await f.arrayBuffer());if(v.getUint32(0)!=0x89504E47){{g.className='r';setTimeout(function(){{g.className=''}},3000);return}}
var o=8,c=null;while(o<v.byteLength){{var l=v.getUint32(o);if(String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7))=='zDAT'){{c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}}o+=12+l}}
if(!c){{g.className='r';setTimeout(function(){{g.className=''}},3000);return}}
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-M){{g.className='r';setTimeout(function(){{g.className=''}},3000);return}}
var ml=dv.getUint16(26),cd=c.subarray(28+ml),r=new Blob([cd]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ch=[];while(true){{var{{value,done}}=await r.read();if(done)break;ch.push(value)}}
var h=new TextDecoder().decode(await(new Blob(ch)).arrayBuffer());
var o2=8,nm='',id='';while(o2<v.byteLength){{var l2=v.getUint32(o2);var t2=String.fromCharCode(v.getUint8(o2+4),v.getUint8(o2+5),v.getUint8(o2+6),v.getUint8(o2+7));if(t2=='zDAT'){{var dd=new DataView(v.buffer,v.byteOffset+o2+8,l2);var ml2=dd.getUint16(26);var mb=new Uint8Array(v.buffer,v.byteOffset+o2+28,ml2);nm=new TextDecoder().decode(mb.slice(1,1+mb[0]));var aid=new Uint8Array(v.buffer,v.byteOffset+o2+14,16);id='';for(var i=0;i<16;i++)id+=aid[i].toString(16).padStart(2,'0');break}}o2+=12+l2}}
var a=C();a=a.filter(function(x){{return x.id!=id}});a.push({{id:id,n:nm||'App',h:h,t:Date.now()}});if(a.length>10)a.shift();S(a);R();
g.className='';document.open();document.write(h);document.close()
}}catch(e){{g.className='r';setTimeout(function(){{g.className=''}},3000)}}}}
R();
</script>"""
    zldr_compressed = __import__('zlib').compress(zldr_html.encode('utf-8'), level=9)
    png_data = create_floppy_png(payload, logo_path=logo_path, zldr_data=zldr_compressed)

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
