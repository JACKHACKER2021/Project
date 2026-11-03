const { chromium } = require('playwright'); const fs = require('fs');
(async () => { const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl'] }); const pg = await b.newPage();
  pg.on('pageerror', e => console.log('PE', e.message));
  await pg.goto('http://localhost:8899/index_x.html'); await pg.waitForFunction(() => window.__x, null, { timeout: 60000 });
  await pg.evaluate(() => Promise.allSettled(__x.LOADS)); await pg.waitForTimeout(3000);
  const exp = async (name, fn) => { const b64 = await pg.evaluate(fn); fs.writeFileSync('remglb/' + name + '.glb', Buffer.from(b64, 'base64')); console.log(name, Buffer.from(b64, 'base64').length); };
  const toB64 = `(r => { const u = new Uint8Array(r); let s = ''; for (let i = 0; i < u.length; i += 32768) s += String.fromCharCode.apply(null, u.subarray(i, i + 32768)); return btoa(s); })`;
  console.log(await pg.evaluate(() => Object.keys(__x.office).join(',')));
  await exp('world', `new Promise((res, rej) => { const X = __x, sc = X.scene; X.office.shutL && (X.office.shutL.name = 'ShutL'); X.office.shutR && (X.office.shutR.name = 'ShutR'); if (X.office.blades) X.office.blades.name = 'FanBlades';
    const skip = new Set([X.VOX.root, X.COC.root, X.pizzaMesh, X.axeMesh]); const root = new X.THREE.Group(); root.name = 'World';
    for (const c of sc.children) { if (skip.has(c) || c.isCamera || !c.visible) continue; if (c.isLight && !c.isPointLight && !c.isSpotLight) continue; root.add(c.clone(true)); }
    root.traverse(o => { if (o.isSprite || o.isPoints) o.visible = false; });
    const inst = []; root.traverse(o => { if (o.isInstancedMesh) inst.push(o); });
    for (const im of inst) { const geos = [], m4 = new X.THREE.Matrix4(), col = new X.THREE.Color(); for (let i = 0; i < im.count; i++) { im.getMatrixAt(i, m4); const g = im.geometry.clone().applyMatrix4(m4); if (im.instanceColor) { im.getColorAt(i, col); const n = g.attributes.position.count, ca = new Float32Array(n * 3); for (let k = 0; k < n; k++) { ca[k * 3] = col.r; ca[k * 3 + 1] = col.g; ca[k * 3 + 2] = col.b; } g.setAttribute('color', new X.THREE.BufferAttribute(ca, 3)); } geos.push(g.index ? g.toNonIndexed() : g); }
      const merged = X.merge(geos); if (!merged) continue; const mt = (Array.isArray(im.material) ? im.material[0] : im.material).clone(); if (im.instanceColor) { mt.vertexColors = true; mt.color && mt.color.set(0xffffff); } const mesh = new X.THREE.Mesh(merged, mt); mesh.name = im.name || 'inst'; mesh.position.copy(im.position); mesh.quaternion.copy(im.quaternion); mesh.scale.copy(im.scale); im.parent.add(mesh); im.parent.remove(im); }
    new X.Exp().parse(root, r => res(${toB64}(r)), e => rej(String(e)), { binary: true, onlyVisible: true }); })`);
  await exp('voxie', `new Promise((res, rej) => { const X = __x, v = X.VOX.root.clone(true); v.position.set(0, 0, 0); v.rotation.set(0, 0, 0); v.visible = true; v.traverse(o => o.visible = true); new X.Exp().parse(v, r => res(${toB64}(r)), e => rej(String(e)), { binary: true }); })`);
  await b.close(); })();
