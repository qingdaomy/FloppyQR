import Foundation

struct LoaderHTMLTemplate {

    static func generate(appId: String, strict: Bool) -> String {
        let s = """
<html><meta name=viewport content="width=device-width,initial-scale=1"><p id=s>选数据盘PNG</p><input type=file accept=image/png id=f><script>
var A='\(appId)',M=0xDA7A10DA,S=\(strict),SEL=document.getElementById('s');
f.onchange=async function(){var f=this.files[0];if(!f)return;SEL.textContent='读取中';
try{
var v=new DataView(await f.arrayBuffer());
if(v.getUint32(0)!==0x89504E47){SEL.textContent='非PNG';return}
var o=8,c=null;
while(o<v.byteLength){var l=v.getUint32(o);if(String.fromCharCode(v.getUint8(o+4),v.getUint8(o+5),v.getUint8(o+6),v.getUint8(o+7))==='zDAT'){c=new Uint8Array(v.buffer,v.byteOffset+o+8,l);break}o+=12+l}
if(!c){SEL.textContent='无数据';return}
var dv=new DataView(c.buffer,c.byteOffset);
if(dv.getUint32(0)-M){SEL.textContent='格式错误';return}
if(S){var a='';for(var k=0;k<16;k++)a+=('0'+c[6+k].toString(16)).slice(-2);if(a!=A){SEL.textContent='ID不匹配';return}}
var ml=dv.getUint16(26);
SEL.textContent='加载中..';
document.open();document.write(new TextDecoder().decode(c.subarray(28+ml)));document.close()
}catch(e){SEL.textContent='错误: '+e.message}}
</script>
"""
        return s
    }
}
