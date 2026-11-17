const {chromium}=require('playwright');const fs=require('fs'),path=require('path');
const MIME={'.html':'text/html','.js':'text/javascript','.glb':'model/gltf-binary'};
(async()=>{const b=await chromium.launch({args:['--no-sandbox','--enable-unsafe-swiftshader']});
const p=await b.newPage({viewport:{width:560,height:560}});
await p.route('http://models.local/**',r=>{const u=new URL(r.request().url());
 const f=path.join(process.cwd(),decodeURIComponent(u.pathname));
 if(!fs.existsSync(f))return r.fulfill({status:404,body:'no'});
 r.fulfill({status:200,contentType:MIME[path.extname(f)]||'application/octet-stream',body:fs.readFileSync(f)});});
const [file,extra,out]=process.argv.slice(2);
await p.goto(`http://models.local/view.html?f=out/${file}&${extra}`);
try{await p.waitForFunction("document.title==='ok'",{timeout:20000});}catch(e){console.log('FAIL',await p.title());}
await p.screenshot({path:out});await b.close();})();
