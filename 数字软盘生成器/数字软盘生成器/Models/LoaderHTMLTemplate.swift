import Foundation

struct LoaderHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<html><meta name=viewport content="width=device-width,initial-scale=1,maximum-scale=1"><style>
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
var A='\(appId)',M=0xDA7A10DA,S=\(strict),st=document.getElementById('st');
f.onchange=async function(){var f=this.files[0];if(!f)return;st.textContent='Read';st.className='';
try{
var v=new DataView(await f.arrayBuffer());if(v.getUint32(0)!==0x89504E47)throw 0
var o=8,c=null;while(o<v.byteLength){var l=v.getUint32(o);if(String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7))==='zDAT'){c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}o+=12+l}
if(!c)throw 0
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-M)throw 0
if(S){var a='';for(var k=0;k<16;k++)a+=('0'+c[6+k].toString(16)).slice(-2);if(a!=A)throw 0}
var ml=dv.getUint16(26),cd=c.subarray(28+ml);
st.textContent='Decompress';
var r=new Blob([cd]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ch=[];
while(true){var{value,done}=await r.read();if(done)break;ch.push(value)}
document.write(new TextDecoder().decode(await new Blob(ch).arrayBuffer()));document.close()
}catch(e){st.textContent='Err';st.className='r';}}
</script>
"""
        return s
    }
}
