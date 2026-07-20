import Foundation

struct LoaderHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<html><meta name=viewport content="width=device-width,initial-scale=1"><style>
*{margin:0;padding:0}body{display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:100vh;color:#64748b}#bw{position:relative}#b{width:192px;height:64px;background:#cbd5e1;border-radius:14px;display:flex;align-items:center;pointer-events:none}#s{margin-left:20px;width:106px;height:22px;background:#dce3ec;border-radius:4px}#l{width:22px;height:22px;border-radius:50%;background:#22c55e;margin:0 20px 0 auto}#l.b{opacity:.5}#l.r{background:#ef4444}#l.y{background:#eab308}input{display:none}
</style>
<label for=f id=bw><div id=b><div id=s></div><div id=l></div></div></label>
<input type=file id=f>
<script>
function D(b,f){var r=new Blob([b]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),a=[];(function n(){r.read().then(function(v){if(v.done){new Blob(a).arrayBuffer().then(function(b){f(new TextDecoder().decode(b))})}else{a.push(v.value);n()}})})()}
(function(){try{var N=JSON.parse(window.name);if(N&&N.s){document.body.innerHTML='';document.write(N.s);return}}catch(e){}
var g=document.getElementById('l'),t=function(){g.className=''};
document.getElementById('f').addEventListener('change',function(){var f=this.files[0];if(!f)return;g.className='b';
f.arrayBuffer().then(function(b){
var v=new DataView(b);if(v.getUint32(0)!=0x89504E47){g.className='r';return}
var o=8,c=null,z=null;while(o<v.byteLength){var l=v.getUint32(o);var x=String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7));if(x=='zDAT')c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);if(x=='zLDR')z=new Uint8Array(v.buffer,v.byteOffset+o+8,l);o+=12+l}
if(!c){g.className='r';return}
var dv=new DataView(c.buffer,c.byteOffset);if(dv.getUint32(0)-0xDA7A10DA){g.className='r';return}
var ml=dv.getUint16(26),mb=c.subarray(28,28+ml),nl=mb[0],nm=nl?new TextDecoder().decode(mb.slice(1,1+nl)):'',vl=mb[1+nl],ver=vl?new TextDecoder().decode(mb.slice(2+nl,2+nl+vl)):'';
D(c.subarray(28+ml),function(H){
var aid=new Uint8Array(c.buffer,c.byteOffset+6,16),id='';for(var i=0;i<16;i++)id+=('0'+aid[i].toString(16)).slice(-2);
if(!z){location.href=URL.createObjectURL(new Blob([H],{type:'text/html'}));return}
D(z,function(Zh){
try{var n=JSON.parse(window.name);var C=n&&n.c?n.c:[]}catch(e){var C=[]}
C=C.filter(function(x){return x.id!=id});C.push({id:id,n:nm,ver:ver,ic:'',h:H,t:Date.now()});
window.name=JSON.stringify({s:Zh,c:C});location.reload()
})})
}).catch(function(){g.className='r'})})
})();
</script>
"""
        return s
    }
}
