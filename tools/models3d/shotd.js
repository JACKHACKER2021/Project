const {chromium}=require('playwright');const fs=require('fs'),path=require('path');
const MIME={'.html':'text/html','.js':'text/javascript','.glb':'model/gltf-binary'};
(async()=>{const b=await chromium.launch({args:['--no-sandbox','--enable-unsafe-swiftshader']});
const p=await b.newPage({viewport:{width:460,height:460}});
await p.route('http://models.local/**',r=>{const u=new URL(r.request().url());
 const f=path.join(process.cwd(),decodeURIComponent(u.pathname));
 if(!fs.existsSync(f))return r.fulfill({status:404,body:'no'});
 r.fulfill({status:200,contentType:MIME[path.extname(f)]||'application/octet-stream',body:fs.readFileSync(f)});});
for(const f of fs.readdirSync('out').filter(x=>x.startsWith('draha')&&x.endsWith('.glb'))){
 await p.goto(`http://models.local/view.html?f=out/${f}&a=28`);
 try{await p.waitForFunction("document.title==='ok'",{timeout:25000});}catch(e){console.log('FAIL',f);continue;}
 await p.screenshot({path:'prev/'+f.replace('.glb','')+'_28.png'});}
console.log('ok');await b.close();})();
