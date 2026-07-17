import Foundation

struct LoaderHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<html><meta name=viewport content="width=device-width,initial-scale=1,maximum-scale=1"><style>
body{background:#f2f5f9;padding:20px;text-align:center}.c{max-width:400px;width:100%;background:#fff;border-radius:20px;padding:24px 16px;display:inline-block}h1{font-size:24px;color:#1e293b;margin:0 0 8px}p{font-size:16px;color:#64748b;margin:0 0 16px}.w{max-width:280px;margin:0 auto}.w input{position:absolute;inset:0;opacity:0}.w label{display:block;background:#2563eb;color:#fff;padding:16px;border-radius:30px}#s{color:#334155;margin-top:16px}#s.g{color:#16a34a}#s.r{color:#dc2626}
</style>
<div class=c>
<h1>FloppyQR</h1>
<p>Add to Bookmarks</p>
<div class=w>
<input type=file accept=image/png id=f>
<label for=f>+ Floppy PNG</label>
</div>
<div id=s>Ready</div>
</div>
<script>
var A='\(appId)',M=0xDA7A10DA,S=\(strict),s=document.getElementById('s');
f.onchange=async function(){var f=this.files[0];if(!f)return;s.textContent='Read';s.className='';
try{
var v=new DataView(await f.arrayBuffer());if(v.getUint32(0)!==0x89504E47)throw 0
var o=8,c=null;while(o<v.byteLength){var l=v.getUint32(o);if(String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7))==='zDAT'){c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}o+=12+l}
if(!c)throw 0
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-M)throw 0
if(S){var a='';for(var k=0;k<16;k++)a+=('0'+c[6+k].toString(16)).slice(-2);if(a!=A)throw 0}
var ml=dv.getUint16(26);document.write(new TextDecoder().decode(c.subarray(28+ml)));document.close()
}catch(e){s.textContent='Err';s.className='r';}}
</script>
"""
        return s
    }
}
