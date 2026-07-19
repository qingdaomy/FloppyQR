#!/usr/bin/env python3
"""
FloppyQR - Core generation library (cross-platform)
"""
import struct, zlib, io, os, re, base64, html as html_mod
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
def create_floppy_png(payload, logo_path=None, size=1024, icon_size=256, zldr_data=None):
    """Create a Floppy PNG with zDAT chunk + optional zLDR chunk."""
    # Create white image
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))

    # Draw logo centered (use default FloppyQR icon if no logo specified)
    logo_img = None
    if logo_path and os.path.exists(logo_path):
        try:
            logo_img = Image.open(logo_path).convert('RGBA')
        except Exception as e:
            print(f"  ⚠️  Logo error: {e}")
    # Always draw a logo (default or user-provided)
    try:
        if logo_img is None:
            logo_img = Image.open(io.BytesIO(_DEFAULT_ICON_PNG)).convert('RGBA')
        logo_img.thumbnail((icon_size, icon_size), Image.Resampling.LANCZOS)
        x = (size - logo_img.width) // 2
        y = (size - logo_img.height) // 2
        img.paste(logo_img, (x, y), logo_img)
    except Exception as e:
        print(f"  ⚠️  Logo draw error: {e}")

    # Save to PNG bytes
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    png_bytes = buf.getvalue()

    # Insert zDAT chunk before IEND
    def make_chunk(ctype, cdata):
        clen = struct.pack('>I', len(cdata))
        crc = zlib.crc32(ctype + cdata) & 0xffffffff
        return clen + ctype + cdata + struct.pack('>I', crc)

    result = png_bytes
    iend_type = result.rfind(b'IEND')
    if iend_type == -1 or iend_type < 4:
        raise RuntimeError("IEND chunk not found")
    iend_start = iend_type - 4
    result = result[:iend_start] + make_chunk(b'zDAT', payload) + result[iend_start:]

    # Insert zLDR chunk if provided
    if zldr_data:
        iend_type2 = result.rfind(b'IEND')
        iend_start2 = iend_type2 - 4
        result = result[:iend_start2] + make_chunk(b'zLDR', zldr_data) + result[iend_start2:]

    return result

# ──────────────────────────────────────────────
#  QR code generation
# ──────────────────────────────────────────────
LOADER_HTML_TEMPLATE = r"""<html><meta name=viewport content="width=device-width,initial-scale=1"><style>
*{margin:0;padding:0}body{display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:100vh;cursor:pointer;color:#64748b}#b{width:192px;height:64px;background:#cbd5e1;border-radius:14px;display:flex;align-items:center}#s{margin-left:20px;width:106px;height:22px;background:#dce3ec;border-radius:4px}#l{width:22px;height:22px;border-radius:50%;background:#22c55e;margin-left:auto;margin-right:20px;transition:all .3s}#l.b{animation:c 1.5s infinite}@keyframes c{50%{opacity:.3}}#l.r{background:#ef4444}#l.y{background:#eab308}#p{font-size:14px;margin-top:20px}input{display:none}
</style>
<div id=b onclick="f.click()"><div id=s></div><div id=l></div></div>
<p id=p>FloppyQR For AIpp Share</p>
<input type=file accept=image/png id=f>
<script>
var A='{APP_ID}',M=0xDA7A10DA,S={STRICT},g=document.getElementById('l'),cl=function(){g.className=''};
f.onchange=async function(){var f=this.files[0];if(!f)return;g.className='b';
try{var v=new DataView(await f.arrayBuffer());if(v.getUint32(0)!=0x89504E47){g.className='r';setTimeout(cl,4000);return}
var o=8,c=null,ld=null;while(o<v.byteLength){var l=v.getUint32(o);var t=String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7));if(t=='zDAT'){c=new Uint8Array(v.buffer,v.byteOffset+o+8,l)}if(t=='zLDR'){ld=new Uint8Array(v.buffer,v.byteOffset+o+8,l)}o+=12+l}
if(!c){g.className='r';setTimeout(cl,4000);return}
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-M){g.className='r';setTimeout(cl,4000);return}
if(S){var a='';for(var k=0;k<16;k++)a+=('0'+c[6+k].toString(16)).slice(-2);if(a!=A){g.className='y';setTimeout(cl,4000);return}}
var ml=dv.getUint16(26),cd=c.subarray(28+ml);
var r=new Blob([cd]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ch=[];
while(true){var{value,done}=await r.read();if(done)break;ch.push(value)}
var h=new TextDecoder().decode(await(new Blob(ch)).arrayBuffer());
if(ld){var rd=new Blob([ld]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ca=[];while(true){var{value,done}=await rd.read();if(done)break;ca.push(value)}var lh=new TextDecoder().decode(await(new Blob(ca)).arrayBuffer());var bl=new Blob([lh],{type:'text/html'});var a2=document.createElement('a');a2.href=URL.createObjectURL(bl);a2.download='FloppyQR.html';a2.click()}
document.write(h);document.close()
}catch(e){g.className='r';setTimeout(cl,4000)}}
</script>"""

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

_DEFAULT_ICON_B64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACl0lEQVR4nO1WTWsTURQ9d+bNtM2YWhNSFEHFIn4h+QMW3QiiuHThT/AXuHcpLhRcuy+I4kJ0YcGN4MKKiEjBCsUUIQXb1JrETCbvyb2Zp0lsM9NUSBY98Dbz7rvv3DP345ExxmCIcIZ5+R6BkVBAJRm0DMB5SkRwqXtPG17tHLb71l45PcbbgIZdBWq7DWbFMTxfruLD6i8Up8dx+Vgg35kyB/hutYGXX6twiXBkUuH6iSweL/1EuRrhZnFKbBm0UwItY8Tpi+Uqrj5ZgQk1bpybEgIsO4vmEOHVSg235svC5vzRjBB4+HEDzz5tYHE9xP2L023CfUioLaOPTyxVQngOwQsUsv6/LgJFyAQKPhFy4658m/QJmayHB+8rotKd2YIEQzRAFXgOCftIG4m8F/WWQa2hsdnU2Ax1rB4QaoODgYt7b9fx9EtViLCP1ApY9B5hJ3yBQBvM7Pcwk/OhtUGxMCb7pkNFVxF+xMQGLkMLlpFLq/PAteP7ZPWqxmpTTELRf+gDgedgvlTD7TffoTp+GkfLyUhx4jZbBq+/1eG7hCiWIqnGVRIBbjQZz0E90ri7sNaVzb3OeS/rOyhMuGi0jChAuyXgApi7cgin874444j7oamN2H2uhLgwV9qdAoYTySW5PB+XWVoox4fn0p9WPRABi3rUlpMrKanFWxs5g2SoFDbikJWX7E4gYG1SziKM/jj+O3bbKwnWJo0tQ6WRM/BIJE0jq7XhM/a3DUwgMkAUGSyUGzh5wN9REnIZhs2O1r0TAhRn2pm8D+7klx6VpKT6jVULa8Nd0XUIp3J+l8/ULyITO+KZv7gWyhxI+3biu3gwnc2PYfbwRF/iNLJPMgv7yBwEWz1kR04BZ5iX7xEYCQV+A6Q6EB6kFhzqAAAAAElFTkSuQmCC"

_DEFAULT_ICON_PNG = base64.b64decode(_DEFAULT_ICON_B64)

def _load_default_icon():
    """Load the embedded FloppyQR logo as 32x32 RGBA bytes."""
    from PIL import Image
    import io
    img = Image.open(io.BytesIO(_DEFAULT_ICON_PNG)).convert('RGBA')
    img = img.resize((32, 32), Image.Resampling.LANCZOS)
    return img.tobytes()

_DEFAULT_ICON_RGBA = _load_default_icon()

def placeholder_icon():
    """FloppyQR logo as 32x32 RGBA bytes."""
    return _DEFAULT_ICON_RGBA
