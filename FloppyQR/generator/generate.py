#!/usr/bin/env python3
"""
FloppyQR - Core generation library (cross-platform)
"""
import struct, zlib, io, os, re, html as html_mod
from PIL import Image
import qrcode
from qrcode.image.styledpil import StyledPilImage
from urllib.parse import quote

MAGIC = 0xDA7A10DA
VERSION = 1

# ──────────────────────────────────────────────
#  Multifile packing
# ──────────────────────────────────────────────
def pack_files(file_dict):
    """Pack multiple files into binary format.
    [count:4BE] [nameLen:2BE][name][dataLen:4BE][data] ...
    """
    packed = struct.pack('>I', len(file_dict))
    for name, content in file_dict.items():
        nb = name.encode('utf-8')
        packed += struct.pack('>H', len(nb))
        packed += nb
        packed += struct.pack('>I', len(content))
        packed += content
    return packed

# ──────────────────────────────────────────────
#  Inline bundler (directory → single HTML)
# ──────────────────────────────────────────────
def bundle_directory(directory):
    """Read index.html, inline CSS/JS/images into a single HTML file."""
    index_path = os.path.join(directory, 'index.html')
    if not os.path.exists(index_path):
        raise FileNotFoundError(f"index.html not found in {directory}")

    with open(index_path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Inline CSS <link rel="stylesheet" href="...">
    html = _inline_tag(html, directory, 'link', 'href', lambda url, ext:
        ('<style>' + open(url, encoding='utf-8').read() + '</style>') if ext == 'css' else None)

    # Inline JS <script src="...">
    html = _inline_tag(html, directory, 'script', 'src', lambda url, ext:
        ('<script>' + open(url, encoding='utf-8').read() + '</script>') if ext == 'js' else None)

    # Inline images
    html = _inline_images(html, directory)

    return html

def _inline_tag(html, base_dir, tag, attr, handler):
    result = html
    search = f'<{tag} '
    attr_mark = f' {attr}="'
    i = 0
    while True:
        s = result.find(search, i)
        if s == -1:
            break
        rest = result[s + len(search):]
        c = rest.find('>')
        a = rest.find(attr_mark)
        if a == -1 or a >= c:
            i = s + 1
            continue
        v_start = a + len(attr_mark)
        v_end = rest.find('"', v_start)
        if v_end == -1 or v_end >= c:
            i = s + 1
            continue
        value = rest[v_start:v_end]
        url = _resolve_url(value, base_dir)
        ext = os.path.splitext(url)[1].lower().lstrip('.')
        tag_end = s + len(search) + c + 1
        tag_str = result[s:tag_end]
        try:
            replacement = handler(url, ext)
            if replacement:
                result = result[:s] + replacement + result[tag_end:]
                i = s
            else:
                i = tag_end
        except:
            i = tag_end
    return result

def _inline_images(html, base_dir):
    result = html
    mark = ' src="'
    i = 0
    while True:
        s = result.find(mark, i)
        if s == -1:
            break
        v_start = s + len(mark)
        v_end = result.find('"', v_start)
        if v_end == -1:
            break
        src = result[v_start:v_end]
        url = _resolve_url(src, base_dir)
        ext = os.path.splitext(url)[1].lower().lstrip('.')
        mime = {
            'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
            'gif': 'image/gif', 'svg': 'image/svg+xml', 'webp': 'image/webp',
            'ico': 'image/x-icon'
        }.get(ext, f'image/{ext}')
        full = f'{mark}{src}"'
        try:
            with open(url, 'rb') as f:
                data = f.read()
            repl = f' src="data:{mime};base64,{__import__("base64").b64encode(data).decode()}"'
            result = result.replace(full, repl, 1)
        except:
            pass
        i = s + 1
    return result

def _resolve_url(src, base_dir):
    if src.startswith('/'):
        return os.path.join(base_dir, src[1:])
    return os.path.normpath(os.path.join(base_dir, src))

# ──────────────────────────────────────────────
#  Payload building
# ──────────────────────────────────────────────
def build_payload(html_data, app_name, app_id_hex, strict=False, icon_rgba=None):
    """Build the binary payload for zDAT chunk."""
    # Compress
    compressed = zlib.compress(html_data, level=9)

    # Metadata
    meta = b''
    nb = app_name.encode('utf-8')
    meta += struct.pack('B', len(nb))
    meta += nb
    # version
    meta += struct.pack('B', 3) + b'1.0'
    # developer
    meta += struct.pack('B', 1) + b'_'
    # icon header + data
    if icon_rgba is None:
        icon_rgba = b'\xc8' * (32 * 32 * 4)
    meta += struct.pack('<III', 32, 32, 4)
    meta += icon_rgba[:4096].ljust(4096, b'\xc8')

    app_id = bytes.fromhex(app_id_hex)
    flags = (1 if strict else 0) | 0x02  # bit0=strict, bit1=compressed

    payload = struct.pack('>I', MAGIC)
    payload += struct.pack('B', VERSION)
    payload += struct.pack('B', flags)
    payload += app_id
    payload += struct.pack('>I', len(html_data))
    payload += struct.pack('>H', len(meta))
    payload += meta
    payload += compressed
    return payload

# ──────────────────────────────────────────────
#  PNG generation (zDAT chunk insertion)
# ──────────────────────────────────────────────
def create_floppy_png(payload, logo_path=None, size=1024, icon_size=256):
    """Create a Floppy PNG with zDAT chunk.
    White background + optional logo at right-bottom corner.
    """
    # Create white image
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))

    # Draw logo centered
    if logo_path and os.path.exists(logo_path):
        try:
            logo = Image.open(logo_path).convert('RGBA')
            max_w, max_h = icon_size, icon_size
            logo.thumbnail((max_w, max_h), Image.Resampling.LANCZOS)
            x = (size - logo.width) // 2
            y = (size - logo.height) // 2
            img.paste(logo, (x, y), logo)
        except Exception as e:
            print(f"  ⚠️  Logo error: {e}")

    # Save to PNG bytes
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    png_bytes = buf.getvalue()

    # Insert zDAT chunk before IEND
    chunk_type = b'zDAT'
    chunk_len = struct.pack('>I', len(payload))
    crc = zlib.crc32(chunk_type + payload) & 0xffffffff
    chunk = chunk_len + chunk_type + payload + struct.pack('>I', crc)

    # Search for IEND chunk (length + type + CRC = 12 bytes)
    # rfind on b'IEND' finds the type field, we need the chunk start
    iend_type = png_bytes.rfind(b'IEND')
    if iend_type == -1 or iend_type < 4:
        raise RuntimeError("IEND chunk not found")
    iend_start = iend_type - 4  # 4 bytes before type = length field
    return png_bytes[:iend_start] + chunk + png_bytes[iend_start:]

# ──────────────────────────────────────────────
#  QR code generation
# ──────────────────────────────────────────────
LOADER_HTML_TEMPLATE = r"""<html><meta name=viewport content="width=device-width,initial-scale=1,maximum-scale=1"><style>
*{margin:0;padding:0}body{background:#f2f5f9;display:flex;justify-content:center;align-items:center;min-height:100vh;padding:20px;font-family:sans-serif}.c{max-width:400px;width:100%;background:#fff;border-radius:24px;padding:32px 20px;text-align:center}h1{font-size:24px;font-weight:600;color:#1e293b;margin-bottom:8px}.s{font-size:16px;color:#64748b;margin-bottom:24px}.w{position:relative;width:100%;max-width:280px;margin:0 auto}.w input{position:absolute;inset:0;opacity:0;cursor:pointer}.w label{display:block;background:#2563eb;color:#fff;padding:16px 20px;border-radius:60px;font-size:18px;font-weight:600}#st{margin-top:16px;font-size:16px;color:#334155}#st.g{color:#16a34a}#st.r{color:#dc2626}
</style>
<div class=c>
<h1>FloppyQR</h1>
<p class=s>Add to Bookmarks</p>
<div class=w>
<input type=file accept=image/png id=f>
<label for=f>+ Floppy PNG</label>
</div>
<div id=st>Ready</div>
</div>
<script>
var A='{APP_ID}',M=0xDA7A10DA,S={STRICT},st=document.getElementById('st');
f.onchange=async function(){var f=this.files[0];if(!f)return;st.textContent='Read';st.className='';
try{var v=new DataView(await f.arrayBuffer());if(v.getUint32(0)!==0x89504E47)throw 0
var o=8,c=null;while(o<v.byteLength){var l=v.getUint32(o);if(String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7))==='zDAT'){c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}o+=12+l}
if(!c)throw 0
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-M)throw 0
if(S){var a='';for(var k=0;k<16;k++)a+=('0'+c[6+k].toString(16)).slice(-2);if(a!=A)throw 0}
var ml=dv.getUint16(26),cd=c.subarray(28+ml);
st.textContent='Decompress';
var r=new Blob([cd]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ch=[];
while(true){var{value,done}=await r.read();if(done)break;ch.push(value)}
document.write(new TextDecoder().decode(await new Blob(ch).arrayBuffer()));document.close()
}catch(e){st.textContent='Err';st.className='r';}}</script>"""

def generate_loader_html(app_id_hex, strict=False):
    """Generate the loader HTML with appId embedded."""
    html = LOADER_HTML_TEMPLATE.replace('{APP_ID}', app_id_hex)
    html = html.replace('{STRICT}', 'true' if strict else 'false')
    return html

def generate_qrboot(loader_html, output_size=1000):
    """Generate QRboot PNG from loader HTML."""
    allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~!*'();:@&=+$,/?%[]{}|"
    encoded = quote(loader_html, safe=allowed)
    data_uri = f"data:text/html;charset=UTF-8,{encoded}"

    qr = qrcode.QRCode(version=None, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=10, border=4)
    qr.add_data(data_uri)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img = img.resize((output_size, output_size), Image.Resampling.NEAREST)

    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return buf.getvalue()

# ──────────────────────────────────────────────
#  Icon processing
# ──────────────────────────────────────────────
def process_icon(image_path, size=32):
    """Load and resize icon to 32x32 RGBA."""
    img = Image.open(image_path).convert('RGBA')
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    return img.tobytes()

def placeholder_icon():
    return b'\xc8' * (32 * 32 * 4)
