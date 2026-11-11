// node capture.mjs <three_dir> <out_dir>  – vyrenderuje snímky preview + exportuje office.glb
import http from 'http'; import fs from 'fs'; import path from 'path'; import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const [threeDir, outDir] = process.argv.slice(2), here = path.dirname(new URL(import.meta.url).pathname);
const srv = http.createServer((q, s) => {
  const u = decodeURIComponent(q.url.split('?')[0]);
  const f = u.startsWith('/three/') ? path.join(threeDir, u.slice(7)) : path.join(here, u);
  fs.readFile(f, (e, d) => { if (e) { s.writeHead(404); return s.end(); } s.writeHead(200, { 'Content-Type': f.endsWith('.js') || f.endsWith('.mjs') ? 'text/javascript' : 'text/html' }); s.end(d); });
}).listen(8765);
const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const p = await b.newPage({ viewport: { width: 1280, height: 720 } });
p.on('console', m => console.log('page:', m.text())); p.on('pageerror', e => console.log('ERR', e.message));
await p.goto('http://localhost:8765/render.html'); await p.waitForFunction('window.ready');
fs.mkdirSync(path.join(outDir, 'frames'), { recursive: true });
fs.writeFileSync(path.join(outDir, 'office.glb'), Buffer.from(await p.evaluate('exportGLB()'), 'base64'));
const FPS = 24, DUR = 18.5, canvas = await p.$('canvas');
for (let f = 0; f < FPS * DUR; f++) {
  await p.evaluate(t => renderFrame(t), f / FPS);
  await canvas.screenshot({ path: path.join(outDir, 'frames', String(f).padStart(4, '0') + '.png') });
}
await b.close(); srv.close();
