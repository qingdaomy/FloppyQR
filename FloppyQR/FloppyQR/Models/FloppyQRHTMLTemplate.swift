import Foundation

struct FloppyQRHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<!DOCTYPE html><html><meta charset=UTF-8><meta name=viewport content="width=device-width,initial-scale=1"><title>FloppyQR</title><style>
*{margin:0;padding:0}body{display:flex;flex-direction:column;align-items:center;min-height:100vh;color:#64748b;cursor:default}#bw{position:relative;margin:20px 0 8px;cursor:pointer}#b{width:192px;height:64px;background:#cbd5e1;border-radius:14px;display:flex;align-items:center;pointer-events:none}#s{margin-left:20px;width:106px;height:22px;background:#dce3ec;border-radius:4px}#l{width:22px;height:22px;border-radius:50%;background:#22c55e;margin-left:auto;margin-right:20px;transition:.3s}#l.b{animation:d 1.5s infinite}@keyframes d{50%{opacity:.3}}#l.r{background:#ef4444}#l.y{background:#eab308}#g{display:grid;grid-template-columns:repeat(4,1fr);gap:16px 12px;width:100%;max-width:360px;padding:0 8px 8px}#t{font:12px sans-serif;color:#94a3b8;margin:0 0 16px}#e{text-align:center;color:#94a3b8;font-size:14px;padding:40px 20px;grid-column:span 4}.i{text-align:center;cursor:pointer;position:relative}.i img{width:64px;height:64px;border-radius:12px;background:#f1f5f9;object-fit:cover;display:block;margin:0 auto}.i .n{font-size:12px;color:#334155;margin-top:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:72px;margin-left:auto;margin-right:auto}.i .v{font-size:10px;color:#94a3b8}.i .del{position:absolute;top:-6px;right:-6px;width:20px;height:20px;border-radius:50%;background:#ef4444;color:#fff;font:14px/20px sans-serif;text-align:center;cursor:pointer;z-index:1;display:none}#ft{width:100%;max-width:360px;color:#94a3b8;font:12px sans-serif;padding:8px 8px 24px;box-sizing:border-box;text-align:center;position:relative}#mb{position:absolute;right:8px;top:50%;transform:translateY(-50%);background:none;border:1px solid #94a3b8;color:#94a3b8;padding:2px 10px;border-radius:10px;font:10px sans-serif;cursor:pointer}input{display:none}
</style>
<label for=f id=bw><div id=b><div id=s></div><div id=l></div></div></label>
<input type=file accept=.png id=f>
<div id=t>My FloppyQR AiPP</div>
<div id=g></div>
<div id=ft><span>Please Pin Tab</span><button id=mb onclick="RM()">Edit</button></div>
<script>
var M=0xDA7A10DA,A='\(appId)',ST=\(strict),L=document.getElementById('l'),MX=false;
var C=[];(function(){try{var d=JSON.parse(window.name);if(Array.isArray(d))C=d}catch(e){}})();
function SV(){try{window.name=JSON.stringify(C)}catch(e){}}
function E(m){document.getElementById('g').innerHTML='<div id=e>'+m+'</div>'}
function RM(){MX=!MX;document.getElementById('mb').textContent=MX?'Done':'Edit';R()}
function R(){var h=document.getElementById('g');h.innerHTML='';if(!C.length){h.innerHTML='<div id=e style=color:#94a3b8;font-size:14px;grid-column:span 4;text-align:center;padding:40px 20px></div>';return}
C.slice().reverse().forEach(function(x){
var d=document.createElement('div');d.className='i';
var img=document.createElement('img');img.src=x.ic||'';img.onerror=function(){this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%2264%22 height=%2264%22><rect fill=%22%23e2e8f0%22 width=%2264%22 height=%2264%22 rx=%2210%22/><text x=%2232%22 y=%2236%22 text-anchor=%22middle%22 fill=%22%2394a3b8%22 font-size=%2230%22>?</text></svg>'};
var n=document.createElement('div');n.className='n';n.textContent=x.n||'';
var v=document.createElement('div');v.className='v';v.textContent=x.ver||'';
d.appendChild(img);d.appendChild(n);d.appendChild(v);
if(MX){var del=document.createElement('div');del.className='del';del.textContent='×';del.onclick=function(e){e.stopPropagation();C=C.filter(function(y){return y.id!=x.id});SV();R()};d.appendChild(del)}
d.onclick=function(){if(!MX)location.href=URL.createObjectURL(new Blob([x.h],{type:'text/html'}))};
h.appendChild(d)})
if(MX)document.querySelectorAll('.i .del').forEach(function(d){d.style.display='block'})}
document.getElementById('f').addEventListener('change',function(){
var F=this.files[0];if(!F)return;L.className='b';
var FR=new FileReader();
FR.onload=function(e){
try{
var v=new DataView(e.target.result);if(v.getUint32(0)!=0x89504E47){L.className='y';E('Cannot recognize');setTimeout(R,3000);return}
var o=8,zd=null;while(o<v.byteLength){var l=v.getUint32(o);var t=String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7));if(t=='zDAT'){zd=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}o+=12+l}
if(!zd){L.className='r';E('Cannot recognize');setTimeout(R,3000);return}
var dv=new DataView(zd.buffer,zd.byteOffset);if(dv.getUint32(0)!=M){L.className='r';E('Cannot recognize');setTimeout(R,3000);return}
var fl=zd[5]&1;if(fl||ST){var aid=new Uint8Array(zd.buffer,zd.byteOffset+6,16),eid='';for(var i=0;i<16;i++)eid+=('0'+aid[i].toString(16)).slice(-2);if(eid!=A){L.className='y';E('ID mismatch');setTimeout(R,3000);return}}
var ml=dv.getUint16(26),mb=zd.subarray(28,28+ml),nl=mb[0],nm=nl>0?new TextDecoder().decode(mb.slice(1,1+nl)):'';
var vl=mb[1+nl];var ver=vl>0?new TextDecoder().decode(mb.slice(2+nl,2+nl+vl)):'';
var cd=zd.subarray(28+ml);
var rd=new Blob([cd]).stream().pipeThrough(new DecompressionStream('deflate')).getReader(),ch=[];
(function NR(){rd.read().then(function(rv){
if(rv.done){
new Blob(ch).arrayBuffer().then(function(a){
var h=new TextDecoder().decode(a);
var aid=new Uint8Array(zd.buffer,zd.byteOffset+6,16),id='';for(var i=0;i<16;i++)id+=('0'+aid[i].toString(16)).slice(-2);
var exit=function(ic){C=C.filter(function(x){return x.id!=id});C.push({id:id,n:nm,ver:ver,ic:ic,h:h,t:Date.now()});SV();location.href=URL.createObjectURL(new Blob([h],{type:'text/html'}))};
try{var img=new Image();var u=URL.createObjectURL(F);
img.onload=function(){try{var s=img.naturalWidth;if(s){var d=s/4|0,p=(s-d)/2|0;var c=document.createElement('canvas');c.width=64;c.height=64;var x=c.getContext('2d');x.drawImage(img,p,p,d,d,0,0,64,64);exit(c.toDataURL())}else{exit('')}}catch(e){exit('')}};
img.onerror=function(){exit('')};
img.src=u
}catch(e){exit('');
}});
return
}
ch.push(rv.value);NR()})})()
}catch(e){L.className='r';E('Cannot recognize');setTimeout(R,3000)}
};
FR.readAsArrayBuffer(F)})
R();
</script>
"""
        return s
    }
}
