const {chromium}=require('playwright');const fs=require('fs'),path=require('path');
const MIME={'.html':'text/html','.js':'text/javascript','.glb':'model/gltf-binary'};
const JOBS=[['radnice',2.6],['nemocnice',2.2],['vezeni',2.6],['soud',4.0],
 ['obchod_sladkosti',2.8],['kouzelnicin_dum',2.5],['dum_kovarikovi',2.3],
 ['dum_kovarikovi_zniceny',2.3],['restaurace_zlata_vidlicka',3.0],['myslivna',2.2],
 ['strazni_vez',9.6],['vlak_regionova',2.4]];
(async()=>{const b=await chromium.launch({args:['--no-sandbox','--enable-unsafe-swiftshader']});
const p=await b.newPage({viewport:{width:460,height:460}});
await p.route('http://models.local/**',r=>{const u=new URL(r.request().url());
 const f=path.join(process.cwd(),decodeURIComponent(u.pathname));
 if(!fs.existsSync(f))return r.fulfill({status:404,body:'no'});
 r.fulfill({status:200,contentType:MIME[path.extname(f)]||'application/octet-stream',body:fs.readFileSync(f)});});
for(const [n,cut] of JOBS){
 await p.goto(`http://models.local/view.html?f=out/${n}.glb&a=12&cut=${cut}`);
 try{await p.waitForFunction("document.title==='ok'",{timeout:20000});}catch(e){console.log('FAIL',n);continue;}
 await p.screenshot({path:`prev/cut_${n}.png`});}
console.log('ok');await b.close();})();
