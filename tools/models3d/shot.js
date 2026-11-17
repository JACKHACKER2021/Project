const {chromium}=require('playwright');
const fs=require('fs'), path=require('path');
const MIME={'.html':'text/html','.js':'text/javascript','.glb':'model/gltf-binary'};
(async()=>{
  const b=await chromium.launch({args:['--no-sandbox','--enable-unsafe-swiftshader']});
  const p=await b.newPage({viewport:{width:560,height:560}});
  await p.route('http://models.local/**',r=>{
    const u=new URL(r.request().url());
    const f=path.join(process.cwd(),decodeURIComponent(u.pathname));
    if(!fs.existsSync(f)){console.log('404',u.pathname,'->',f);return r.fulfill({status:404,body:'no'});}
    r.fulfill({status:200,contentType:MIME[path.extname(f)]||'application/octet-stream',
               body:fs.readFileSync(f)});
  });
  p.on('console',m=>console.log('C:',m.type(),m.text()));
  p.on('pageerror',e=>console.log('PE:',e.message));
  const files=process.argv[2]?[process.argv[2]]:fs.readdirSync('out').filter(x=>x.endsWith('.glb'));
  for(const f of files){
    for(const a of [35,215]){
      await p.goto(`http://models.local/view.html?f=out/${f}&a=${a}`);
      try{await p.waitForFunction("document.title==='ok'",{timeout:20000});}
      catch(e){console.log('FAIL',f,a,await p.title());continue;}
      await p.screenshot({path:'prev/'+f.replace('.glb','')+'_'+a+'.png'});
    }
  }
  console.log('done',files.length);
  await b.close();
})();
