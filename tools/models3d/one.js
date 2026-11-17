const {chromium}=require('playwright');
(async()=>{
  const b=await chromium.launch({args:['--no-sandbox','--use-gl=swiftshader','--enable-unsafe-swiftshader']});
  const p=await b.newPage({viewport:{width:520,height:520}});
  p.on('console',m=>console.log('C:',m.type(),m.text()));
  p.on('pageerror',e=>console.log('PE:',e.message));
  await p.goto('file://'+process.cwd()+'/view.html?f=out/radnice.glb&a=35');
  await p.waitForTimeout(6000);
  console.log('title=',await p.title());
  await p.screenshot({path:'prev/_test.png'});
  await b.close();
})();
