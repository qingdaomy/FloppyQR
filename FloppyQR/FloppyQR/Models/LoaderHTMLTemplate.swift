import Foundation

struct LoaderHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<html><meta name=viewport content="width=device-width,initial-scale=1"><style>
*{margin:0;padding:0}body{display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:100vh;color:#64748b}#bw{position:relative;cursor:pointer}#b{width:192px;height:64px;background:#cbd5e1;border-radius:14px;display:flex;align-items:center;pointer-events:none}#s{margin-left:20px;width:106px;height:22px;background:#dce3ec;border-radius:4px}#l{width:22px;height:22px;border-radius:50%;background:#22c55e;margin-left:auto;margin-right:20px;transition:.3s}#l.b{animation:d 1.5s infinite}@keyframes d{50%{opacity:.3}}#l.r{background:#ef4444}#l.y{background:#eab308}input{display:none}
</style>
<label for=f id=bw><div id=b><div id=s></div><div id=l></div></div></label>
<input type=file accept=.png id=f>
<script>
var g=document.getElementById('l'),t=function(){g.className=''};
document.getElementById('f').addEventListener('change',function(){var f=this.files[0];if(!f)return;g.className='b';
f.arrayBuffer().then(function(buf){
var v=new DataView(buf);if(v.getUint32(0)!=0x89504E47){g.className='r';setTimeout(t,4000);return}
var o=8;while(o<v.byteLength){var l=v.getUint32(o);var x=String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7));if(x=='zLDR'){var zd=new Uint8Array(v.buffer,v.byteOffset+o+8,l);
var rd=new Blob([zd]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ca=[];
(function n(){rd.read().then(function(r){if(r.done){new Blob(ca).arrayBuffer().then(function(a){location.href=URL.createObjectURL(new Blob([new TextDecoder().decode(a)],{type:'text/html'}))});return}ca.push(r.value);n()})})();return}o+=12+l}
g.className='r';setTimeout(t,4000)
}).catch(function(){g.className='r';setTimeout(t,4000)})})
</script>
"""
        return s
    }
}
