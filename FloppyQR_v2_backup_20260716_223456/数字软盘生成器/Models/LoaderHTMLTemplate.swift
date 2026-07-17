import Foundation

struct LoaderHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<html><meta name=viewport content="width=device-width,initial-scale=1,maximum-scale=1"><style>
*{margin:0;padding:0}body{font-family:-apple-system,sans-serif;background:#f2f5f9;display:flex;justify-content:center;align-items:center;min-height:100vh;padding:20px}.card{max-width:400px;width:100%;background:#fff;border-radius:28px;padding:32px 24px;text-align:center;box-shadow:0 8px 30px rgba(0,0,0,0.08)}h1{font-size:24px;font-weight:600;color:#1e293b;margin-bottom:8px}p.sub{font-size:16px;color:#64748b;margin-bottom:24px}.file-wrap{position:relative;display:inline-block;width:100%;max-width:280px;margin:0 auto}.file-wrap input{position:absolute;top:0;left:0;width:100%;height:100%;opacity:0;cursor:pointer}.file-wrap label{display:block;background:#2563eb;color:#fff;padding:16px 20px;border-radius:60px;font-size:18px;font-weight:600;transition:0.2s}.file-wrap label:active{transform:scale(0.96)}#status{margin-top:16px;font-size:16px;color:#334155;min-height:2em}#status.ok{color:#16a34a}#status.err{color:#dc2626}
</style>
<div class=card>
<h1>FloppyQR</h1>
<p class=sub>请添加至书签</p>
<div class=file-wrap>
<input type=file accept=image/png id=f>
<label for=f>请选择Floppy PNG</label>
</div>
<div id=status>等待加载…</div>
</div>
<script>
var A='\(appId)',M=0xDA7A10DA,S=\(strict),st=document.getElementById('status');
f.onchange=async function(){var f=this.files[0];if(!f)return;st.textContent='读取中';st.className='';
try{
var v=new DataView(await f.arrayBuffer());if(v.getUint32(0)!==0x89504E47){st.textContent='非PNG';st.className='err';return}
var o=8,c=null;while(o<v.byteLength){var l=v.getUint32(o);if(String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7))==='zDAT'){c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}o+=12+l}
if(!c){st.textContent='无数据';st.className='err';return}
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-M){st.textContent='格式错误';st.className='err';return}
if(S){var a='';for(var k=0;k<16;k++)a+=('0'+c[6+k].toString(16)).slice(-2);if(a!=A){st.textContent='ID不匹配';st.className='err';return}}
var ml=dv.getUint16(26);var h=new TextDecoder().decode(c.subarray(28+ml));
st.textContent='加载成功';st.className='ok';
document.write(h);document.close()
}catch(e){st.textContent='错误: '+e.message;st.className='err';}}
</script>
"""
        return s
    }
}
