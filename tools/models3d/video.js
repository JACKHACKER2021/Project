const {chromium}=require('playwright');const fs=require('fs'),path=require('path');
const MIME={'.html':'text/html','.js':'text/javascript','.glb':'model/gltf-binary'};
(async()=>{
 const b=await chromium.launch({args:['--no-sandbox','--enable-unsafe-swiftshader']});
 const p=await b.newPage({viewport:{width:720,height:720}});
 await p.route('http://models.local/**',r=>{const u=new URL(r.request().url());
  const f=path.join(process.cwd(),decodeURIComponent(u.pathname));
  if(!fs.existsSync(f))return r.fulfill({status:404,body:'no'});
  r.fulfill({status:200,contentType:MIME[path.extname(f)]||'application/octet-stream',body:fs.readFileSync(f)});});
 p.on('pageerror',e=>console.log('PE:',e.message));
 await p.goto('http://models.local/morph.html');
 await p.waitForFunction("document.title==='ok'",{timeout:40000});
 fs.mkdirSync('frames',{recursive:true});
 const N=125;                       // 5 s at 25 fps
 for(let i=0;i<N;i++){
   const t=i/(N-1);
   await p.evaluate(([t,i])=>window.setT(t,i*0.04),[t,i]);
   await p.screenshot({path:`frames/f${String(i).padStart(3,'0')}.png`});
 }
 console.log('frames done');await b.close();})();
