// Escape – OFFICE (stará budova, funkční výtah). Procedurální model + animace pro preview.
// Souřadnice: 1 jednotka = 1 m, Y nahoru. Kancelář x[-3,3] z[-2.5,2.5], chodba z[2.5,4.5], výtah x[0.6,2.4] z[4.5,6.3].
import * as THREE from 'three';

const H = 3.2;

function canvasTex(w, h, draw, rep = [1, 1]) {
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  draw(c.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(rep[0], rep[1]);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}
const rnd = (() => { let s = 1234; return () => ((s = (s * 16807) % 2147483647) / 2147483647); })();

function makeTextures() {
  const parquet = canvasTex(256, 256, (g, w, h) => {
    for (let y = 0; y < 8; y++) for (let x = 0; x < 2; x++) {
      const l = 30 + rnd() * 12;
      g.fillStyle = `hsl(28,45%,${l}%)`; g.fillRect(x * 128 + ((y % 2) * 64), y * 32, 128, 32);
      g.fillRect(x * 128 + ((y % 2) * 64) - 256, y * 32, 128, 32);
      g.strokeStyle = 'rgba(0,0,0,.45)'; g.strokeRect(x * 128 + ((y % 2) * 64), y * 32, 128, 32);
      for (let i = 0; i < 6; i++) { g.strokeStyle = 'rgba(40,20,5,.15)'; g.beginPath(); const yy = y * 32 + rnd() * 32; g.moveTo(0, yy); g.lineTo(w, yy + rnd() * 4); g.stroke(); }
    }
  }, [3, 3]);
  const plaster = canvasTex(256, 256, (g, w, h) => {
    g.fillStyle = '#6b7a58'; g.fillRect(0, 0, w, h);
    for (let i = 0; i < 3000; i++) { g.fillStyle = `rgba(${rnd() < .5 ? '0,0,0' : '255,255,230'},${rnd() * .08})`; g.fillRect(rnd() * w, rnd() * h, 2, 2); }
    for (let i = 0; i < 7; i++) { // oprýskaná místa
      g.fillStyle = 'rgba(200,190,160,.55)'; g.beginPath(); const x = rnd() * w, y = rnd() * h;
      for (let a = 0; a < 6.3; a += .5) g.lineTo(x + Math.cos(a) * (6 + rnd() * 14), y + Math.sin(a) * (6 + rnd() * 10));
      g.fill();
    }
    g.fillStyle = 'rgba(60,45,20,.25)'; g.fillRect(0, 0, w, 18); // zašlé u stropu
  }, [2, 1]);
  const panel = canvasTex(256, 128, (g, w, h) => {
    g.fillStyle = '#4a2c16'; g.fillRect(0, 0, w, h);
    for (let x = 0; x < 4; x++) {
      g.fillStyle = '#3a210f'; g.fillRect(x * 64 + 8, 14, 48, h - 28);
      g.strokeStyle = '#6a4224'; g.lineWidth = 3; g.strokeRect(x * 64 + 8, 14, 48, h - 28);
    }
    for (let i = 0; i < 40; i++) { g.strokeStyle = 'rgba(0,0,0,.12)'; g.beginPath(); const y = rnd() * h; g.moveTo(0, y); g.lineTo(w, y + 3); g.stroke(); }
  }, [3, 1]);
  const rust = canvasTex(128, 128, (g, w, h) => {
    g.fillStyle = '#5a5c5a'; g.fillRect(0, 0, w, h);
    for (let i = 0; i < 400; i++) { g.fillStyle = `rgba(120,55,20,${rnd() * .35})`; g.beginPath(); g.arc(rnd() * w, rnd() * h, rnd() * 5, 0, 7); g.fill(); }
  });
  const rug = canvasTex(256, 256, (g, w, h) => {
    g.fillStyle = '#5e1a17'; g.fillRect(0, 0, w, h);
    g.strokeStyle = '#b08a3a'; g.lineWidth = 6; g.strokeRect(14, 14, w - 28, h - 28);
    g.strokeStyle = '#1e2a40'; g.lineWidth = 10; g.strokeRect(34, 34, w - 68, h - 68);
    g.fillStyle = '#b08a3a'; g.beginPath(); g.moveTo(w / 2, 60); g.lineTo(w - 60, h / 2); g.lineTo(w / 2, h - 60); g.lineTo(60, h / 2); g.fill();
    g.fillStyle = '#5e1a17'; g.beginPath(); g.arc(w / 2, h / 2, 34, 0, 7); g.fill();
  });
  const clockFace = canvasTex(128, 128, (g, w) => {
    g.fillStyle = '#e8dcc0'; g.fillRect(0, 0, w, w);
    g.fillStyle = '#222'; g.font = 'bold 14px serif'; g.textAlign = 'center'; g.textBaseline = 'middle';
    const R = ['XII', 'I', 'II', 'III', 'IIII', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI'];
    R.forEach((r, i) => { const a = i / 12 * Math.PI * 2 - Math.PI / 2; g.fillText(r, 64 + Math.cos(a) * 48, 64 + Math.sin(a) * 48); });
    // 4:17 (nápověda)
    g.strokeStyle = '#111'; g.lineCap = 'round';
    const ha = (4 + 17 / 60) / 12 * Math.PI * 2 - Math.PI / 2, ma = 17 / 60 * Math.PI * 2 - Math.PI / 2;
    g.lineWidth = 5; g.beginPath(); g.moveTo(64, 64); g.lineTo(64 + Math.cos(ha) * 26, 64 + Math.sin(ha) * 26); g.stroke();
    g.lineWidth = 3; g.beginPath(); g.moveTo(64, 64); g.lineTo(64 + Math.cos(ma) * 40, 64 + Math.sin(ma) * 40); g.stroke();
  });
  const dial = canvasTex(256, 128, (g, w, h) => {
    g.fillStyle = '#c9a54a'; g.fillRect(0, 0, w, h);
    g.fillStyle = '#1b1408'; g.beginPath(); g.arc(128, 124, 110, Math.PI, 0); g.fill();
    g.fillStyle = '#e8d9a8'; g.font = 'bold 20px serif'; g.textAlign = 'center';
    ['S', 'P', '1', '2', '3'].forEach((t, i) => { const a = Math.PI + (i + .5) / 5 * Math.PI; g.fillText(t, 128 + Math.cos(a) * 85, 124 + Math.sin(a) * 85 + 7); });
  });
  const doc = canvasTex(64, 64, (g) => { g.fillStyle = '#d8ceb0'; g.fillRect(0, 0, 64, 64); g.fillStyle = '#555'; for (let y = 8; y < 60; y += 6) g.fillRect(6, y, 30 + rnd() * 22, 2); });
  return { parquet, plaster, panel, rust, rug, clockFace, dial, doc };
}

export function buildOffice() {
  const T = makeTextures();
  const M = {
    floor: new THREE.MeshStandardMaterial({ map: T.parquet, roughness: .7 }),
    wall: new THREE.MeshStandardMaterial({ map: T.plaster, roughness: .95 }),
    panel: new THREE.MeshStandardMaterial({ map: T.panel, roughness: .6 }),
    wood: new THREE.MeshStandardMaterial({ color: '#5a3518', roughness: .55 }),
    darkWood: new THREE.MeshStandardMaterial({ color: '#33200f', roughness: .6 }),
    brass: new THREE.MeshStandardMaterial({ color: '#c9a54a', roughness: .3, metalness: .9 }),
    iron: new THREE.MeshStandardMaterial({ color: '#2b2b2b', roughness: .5, metalness: .8 }),
    rust: new THREE.MeshStandardMaterial({ map: T.rust, roughness: .8, metalness: .5 }),
    steelGrey: new THREE.MeshStandardMaterial({ color: '#59605a', roughness: .6, metalness: .6 }),
    rug: new THREE.MeshStandardMaterial({ map: T.rug, roughness: 1 }),
    cloth: new THREE.MeshStandardMaterial({ color: '#2a2a30', roughness: 1 }),
    glass: new THREE.MeshStandardMaterial({ color: '#2a3c55', roughness: .1, metalness: .2, transparent: true, opacity: .45 }),
    clock: new THREE.MeshStandardMaterial({ map: T.clockFace, roughness: .5 }),
    dial: new THREE.MeshStandardMaterial({ map: T.dial, roughness: .4, metalness: .4 }),
    paper: new THREE.MeshStandardMaterial({ map: T.doc, roughness: 1 }),
    bulb: new THREE.MeshStandardMaterial({ color: '#ffe3a0', emissive: '#ffcf70', emissiveIntensity: 2 }),
    tube: new THREE.MeshStandardMaterial({ color: '#dfefff', emissive: '#cfe6ff', emissiveIntensity: 1.5 }),
    btnOff: new THREE.MeshStandardMaterial({ color: '#efe4c8', roughness: .4 }),
    plank: new THREE.MeshStandardMaterial({ color: '#4d3a26', roughness: .9 }),
    green: new THREE.MeshStandardMaterial({ color: '#2f4a2c', roughness: .7 }),
  };
  const root = new THREE.Group(); root.name = 'Office';
  const box = (p, name, sx, sy, sz, x, y, z, m, ry = 0) => {
    const o = new THREE.Mesh(new THREE.BoxGeometry(sx, sy, sz), m); o.name = name;
    o.position.set(x, y, z); o.rotation.y = ry; o.castShadow = o.receiveShadow = true; p.add(o); return o;
  };
  const cyl = (p, name, r, h, x, y, z, m, seg = 16) => {
    const o = new THREE.Mesh(new THREE.CylinderGeometry(r, r, h, seg), m); o.name = name;
    o.position.set(x, y, z); o.castShadow = true; p.add(o); return o;
  };
  const grp = (p, name, x = 0, y = 0, z = 0) => { const g = new THREE.Group(); g.name = name; g.position.set(x, y, z); p.add(g); return g; };

  // ---------- Stavba ----------
  const shell = grp(root, 'Shell');
  box(shell, 'floor_office', 6, .1, 5, 0, -.05, 0, M.floor);
  box(shell, 'floor_corridor', 6, .1, 2, 0, -.05, 3.5, M.floor);
  const wallWithWainscot = (name, len, x, z, ry, hole) => {
    const g = grp(shell, name, x, 0, z); g.rotation.y = ry;
    const parts = hole ? [[-len / 2, hole[0]], [hole[1], len / 2]] : [[-len / 2, len / 2]];
    for (const [a, b] of parts) {
      const w = b - a, c = (a + b) / 2;
      box(g, 'plaster', w, H, .15, c, H / 2, 0, M.wall);
      box(g, 'wainscot', w, 1.1, .04, c, .55, .095, M.panel);
      box(g, 'rail', w, .06, .07, c, 1.12, .1, M.darkWood);
    }
    if (hole) { box(g, 'lintel', hole[1] - hole[0], H - 2.2, .15, (hole[0] + hole[1]) / 2, 2.2 + (H - 2.2) / 2, 0, M.wall); }
    return g;
  };
  wallWithWainscot('wall_north', 6, 0, -2.5, 0);
  wallWithWainscot('wall_west', 5, -3, 0, Math.PI / 2);
  wallWithWainscot('wall_east', 5, 3, 0, -Math.PI / 2);
  wallWithWainscot('wall_office_corridor', 6, 0, 2.5, Math.PI, [-.5, .5]); // dveře z kanceláře
  wallWithWainscot('wall_corridor_south', 6, 0, 4.5, Math.PI, [-2.4, -.6]); // otvor výtahu (x 0.6..2.4 po otočení)
  // okno (severní zeď) – zatlučené
  const win = grp(shell, 'window', -1.5, 1.8, -2.42);
  box(win, 'frame', 1.3, 1.5, .08, 0, 0, 0, M.darkWood);
  box(win, 'glass', 1.1, 1.3, .02, 0, 0, .03, M.glass);
  [-.35, .1, .45].forEach((y, i) => box(win, 'plank' + i, 1.5, .16, .04, 0, y, .08, M.plank).rotation.z = (i - 1) * .12);
  // dveře kanceláře (pootevřené)
  const door = grp(shell, 'office_door', -.5, 0, 2.5);
  const leaf = box(door, 'leaf', .98, 2.15, .05, .49, 1.075, 0, M.wood); door.rotation.y = -1.1;
  box(door, 'glass_pane', .6, .7, .02, .49, 1.6, .03, M.glass);
  cyl(door, 'knob', .035, .08, .88, 1.0, .06, M.brass).rotation.x = Math.PI / 2;
  // zával schodiště (západní konec chodby)
  const rubble = grp(shell, 'stair_rubble', -2.6, 0, 3.5);
  for (let i = 0; i < 6; i++) { const b = box(rubble, 'beam' + i, 2.2, .18, .18, 0, .2 + i * .25, (rnd() - .5) * 1.2, M.plank); b.rotation.set(rnd() - .5, Math.PI / 2 + rnd() - .5, (rnd() - .5) * 1.2); }
  for (let i = 0; i < 10; i++) box(rubble, 'brick' + i, .25, .12, .14, (rnd() - .5) * .8, .06, (rnd() - .5) * 1.6, M.rust, rnd() * 3);

  // ---------- Nábytek ----------
  const desk = grp(root, 'desk', -1.2, 0, -1.2);
  box(desk, 'top', 1.6, .06, .8, 0, .76, 0, M.wood);
  box(desk, 'pedestal_L', .45, .73, .75, -.55, .365, 0, M.wood);
  box(desk, 'pedestal_R', .45, .73, .75, .55, .365, 0, M.wood);
  const drawer = box(desk, 'drawer_locked', .4, .18, .03, .55, .6, .39, M.darkWood); drawer.userData.interactive = 'desk_drawer';
  cyl(desk, 'keyhole', .015, .02, .55, .6, .41, M.brass).rotation.x = Math.PI / 2;
  box(desk, 'blotter', .6, .01, .4, 0, .795, .05, M.green);
  box(desk, 'papers', .22, .02, .3, -.45, .8, -.1, M.paper, .3);
  const lamp = grp(desk, 'desk_lamp', .5, .79, -.2); lamp.userData.interactive = 'lamp';
  cyl(lamp, 'base', .08, .03, 0, .015, 0, M.brass);
  cyl(lamp, 'stem', .012, .35, 0, .19, 0, M.brass);
  const shade = new THREE.Mesh(new THREE.CylinderGeometry(.15, .12, .1, 20, 1, true), M.green); shade.material = M.green.clone(); shade.material.side = THREE.DoubleSide;
  shade.position.set(0, .36, .05); shade.rotation.x = .25; shade.name = 'shade'; lamp.add(shade);
  cyl(lamp, 'bulb', .03, .05, 0, .35, .05, M.bulb);
  // telefon
  const phone = grp(desk, 'phone', -.1, .79, -.2);
  box(phone, 'body', .18, .07, .22, 0, .035, 0, M.iron); box(phone, 'handset', .22, .04, .05, 0, .09, 0, M.iron);
  // židle
  const chair = grp(root, 'chair', -1.1, 0, -.4); chair.rotation.y = .3;
  box(chair, 'seat', .48, .06, .45, 0, .47, 0, M.wood);
  box(chair, 'back', .44, .5, .04, 0, .78, .2, M.wood);
  [[-.2, -.18], [.2, -.18], [-.2, .2], [.2, .2]].forEach(([x, z], i) => cyl(chair, 'leg' + i, .02, .46, x, .23, z, M.darkWood, 8));
  // sejf
  const safe = grp(root, 'safe', 1.6, 0, -2.0); safe.userData.interactive = 'safe';
  box(safe, 'body', .7, .9, .6, 0, .45, 0, M.steelGrey);
  box(safe, 'door', .58, .78, .03, 0, .45, .31, M.steelGrey);
  cyl(safe, 'dial', .07, .03, 0, .55, .33, M.brass, 24).rotation.x = Math.PI / 2;
  box(safe, 'handle', .04, .16, .04, .18, .4, .34, M.brass);
  // kartotéka
  const cab = grp(root, 'filing_cabinet', 2.55, 0, -.2); cab.userData.interactive = 'cabinet'; cab.rotation.y = -Math.PI / 2;
  box(cab, 'body', .5, 1.35, .6, 0, .675, 0, M.steelGrey);
  for (let i = 0; i < 4; i++) { box(cab, 'drawer' + i, .44, .28, .02, 0, .2 + i * .32, .31, M.steelGrey); box(cab, 'pull' + i, .12, .025, .03, 0, .26 + i * .32, .33, M.brass); }
  // regál
  const shelf = grp(root, 'bookshelf', .9, 0, -2.25);
  box(shelf, 'frame_L', .04, 2.0, .35, -.6, 1.0, 0, M.wood); box(shelf, 'frame_R', .04, 2.0, .35, .6, 1.0, 0, M.wood);
  for (let i = 0; i < 5; i++) box(shelf, 'board' + i, 1.2, .03, .35, 0, .1 + i * .47, 0, M.wood);
  for (let i = 0; i < 4; i++) for (let b = 0; b < 9; b++) if (rnd() > .25) {
    const hh = .25 + rnd() * .15; const m = new THREE.MeshStandardMaterial({ color: new THREE.Color().setHSL(rnd(), .35, .22), roughness: .9 });
    box(shelf, `book${i}_${b}`, .08, hh, .25, -.52 + b * .12, .12 + i * .47 + hh / 2, 0, m, (rnd() - .5) * .2);
  }
  // hodiny (stojí na 4:17)
  const clock = grp(root, 'wall_clock', -2.9, 2.1, .8); clock.rotation.y = Math.PI / 2; clock.userData.interactive = 'clock';
  box(clock, 'case', .5, 1.0, .14, 0, -.2, 0, M.darkWood);
  const face = new THREE.Mesh(new THREE.CircleGeometry(.19, 32), M.clock); face.name = 'face'; face.position.set(0, .05, .075); clock.add(face);
  cyl(clock, 'pendulum_rod', .008, .4, 0, -.35, .06, M.brass, 6);
  cyl(clock, 'pendulum_bob', .06, .015, 0, -.56, .06, M.brass, 20).rotation.x = Math.PI / 2;
  // věšák s kabátem
  const coat = grp(root, 'coat_rack', -2.5, 0, 2.0); coat.userData.interactive = 'coat';
  cyl(coat, 'pole', .025, 1.8, 0, .9, 0, M.darkWood, 8);
  cyl(coat, 'foot', .25, .04, 0, .02, 0, M.darkWood, 16);
  const coatMesh = new THREE.Mesh(new THREE.CylinderGeometry(.14, .28, 1.0, 12), M.cloth); coatMesh.name = 'coat'; coatMesh.position.set(.08, 1.15, 0); coat.add(coatMesh);
  cyl(coat, 'hat', .16, .1, 0, 1.85, 0, M.cloth);
  // koberec
  box(root, 'rug', 2.4, .01, 1.7, .3, .005, .7, M.rug).receiveShadow = true;
  // stropní svítidla (bez stropu – řez pro preview)
  const ceilLamp = grp(root, 'ceiling_lamp_office', 0, 2.75, 0);
  cyl(ceilLamp, 'cord', .006, .45, 0, .225, 0, M.iron, 6);
  const globe = new THREE.Mesh(new THREE.SphereGeometry(.16, 20, 14), M.bulb.clone()); globe.material.emissiveIntensity = .4; globe.name = 'globe'; ceilLamp.add(globe);
  const tube = grp(root, 'corridor_tube', 0, 3.0, 3.5); box(tube, 'tube', 1.2, .05, .05, 0, 0, 0, M.tube);

  // pojistková skříň (chodba, severní stěna z=2.5 z chodby)
  const fuse = grp(root, 'fuse_box', -1.6, 1.5, 2.6); fuse.userData.interactive = 'fuse_box';
  box(fuse, 'box', .55, .7, .14, 0, 0, 0, M.rust);
  const fuseDoor = grp(fuse, 'fuse_door_hinge', -.275, 0, .08); fuseDoor.rotation.y = -1.2;
  box(fuseDoor, 'fuse_door', .55, .7, .02, .275, 0, 0, M.rust);
  for (let i = 0; i < 3; i++) for (let j = 0; j < 2; j++) if (!(i === 2 && j === 1)) cyl(fuse, `fuse_${i}${j}`, .03, .08, -.12 + i * .12, .12 - j * .25, .08, M.btnOff).rotation.x = Math.PI / 2;
  // chybějící pojistka -> prázdná objímka
  cyl(fuse, 'fuse_socket_empty', .035, .02, .12, -.13, .075, M.iron).rotation.x = Math.PI / 2;

  // ---------- VÝTAH ----------
  const elev = grp(root, 'Elevator', 1.5, 0, 4.5);
  // šachta (rezavé plechy) – x -0.9..0.9, z 0..1.8
  const shaft = grp(elev, 'shaft', 0, 0, 0);
  box(shaft, 'shaft_back', 1.9, 14, .08, 0, -5, 1.9, M.rust);
  box(shaft, 'shaft_L', .08, 14, 1.9, -.95, -5, .95, M.rust);
  box(shaft, 'shaft_R', .08, 14, 1.9, .95, -5, .95, M.rust);
  // portál ve chodbě
  const portal = grp(elev, 'portal', 0, 0, -.08);
  box(portal, 'jamb_L', .12, 2.3, .1, -.86, 1.15, 0, M.brass);
  box(portal, 'jamb_R', .12, 2.3, .1, .86, 1.15, 0, M.brass);
  box(portal, 'header', 1.84, .14, .1, 0, 2.3, 0, M.brass);
  // indikátor pater nad dveřmi
  const ind = grp(portal, 'floor_indicator', 0, 2.62, -.03);
  const dialPlane = new THREE.Mesh(new THREE.PlaneGeometry(.7, .35), M.dial); dialPlane.rotation.y = Math.PI; dialPlane.name = 'dial'; ind.add(dialPlane);
  const needle = grp(ind, 'needle', 0, -.16, -.01);
  box(needle, 'needle_bar', .012, .24, .01, 0, .12, 0, M.iron);
  // přivolávací tlačítko
  const call = grp(portal, 'call_button', 1.1, 1.2, -.02);
  box(call, 'plate', .12, .2, .02, 0, 0, 0, M.brass);
  const callBtn = cyl(call, 'btn', .025, .02, 0, 0, -.015, M.btnOff); callBtn.rotation.x = Math.PI / 2;

  // kabina (pohyblivá)
  const car = grp(elev, 'car', 0, 0, 0); car.userData.interactive = 'elevator_car';
  box(car, 'car_floor', 1.7, .08, 1.7, 0, -.04, .9, M.floor);
  box(car, 'car_back', 1.7, 2.3, .05, 0, 1.15, 1.75, M.panel);
  box(car, 'car_L', .05, 2.3, 1.7, -.85, 1.15, .9, M.panel);
  box(car, 'car_R', .05, 2.3, 1.7, .85, 1.15, .9, M.panel);
  box(car, 'car_roof', 1.7, .06, 1.7, 0, 2.33, .9, M.darkWood);
  box(car, 'handrail', 1.5, .04, .04, 0, .95, 1.68, M.brass);
  const carBulb = new THREE.Mesh(new THREE.SphereGeometry(.08, 16, 10), M.bulb); carBulb.name = 'car_bulb'; carBulb.position.set(0, 2.24, .9); car.add(carBulb);
  // lano + kladka
  cyl(car, 'cable', .02, 6, 0, 5.3, .9, M.iron, 6);
  cyl(car, 'hanger', .05, .2, 0, 2.45, .9, M.iron, 8);
  // ovládací panel v kabině (pravá stěna)
  const ctl = grp(car, 'control_panel', .82, 1.25, .45); ctl.rotation.y = -Math.PI / 2; ctl.userData.interactive = 'elevator_panel';
  box(ctl, 'plate', .26, .6, .02, 0, 0, 0, M.brass);
  const buttons = {};
  ['3', '2', '1', 'P', 'S'].forEach((n, i) => {
    const b = cyl(ctl, 'btn_' + n, .03, .03, 0, .2 - i * .09, .02, M.btnOff.clone(), 16); b.rotation.x = Math.PI / 2; buttons[n] = b;
  });
  const keySw = cyl(ctl, 'key_switch', .035, .02, 0, -.26, .02, M.iron, 16); keySw.rotation.x = Math.PI / 2;
  // nůžková mříž (pohyblivá) – na přední hraně kabiny
  const gate = grp(car, 'scissor_gate', -.8, 0, .05); gate.userData.interactive = 'elevator_gate';
  const gateBars = [];
  const N = 9;
  for (let i = 0; i < N; i++) {
    const v = box(gate, 'stile' + i, .025, 2.1, .025, 0, 1.08, 0, M.brass); gateBars.push({ v, i });
    for (let k = 0; k < 4; k++) {
      const d1 = box(gate, `x${i}_${k}a`, .015, .6, .01, 0, .3 + k * .5, .015, M.brass);
      const d2 = box(gate, `x${i}_${k}b`, .015, .6, .01, 0, .3 + k * .5, -.015, M.brass);
      gateBars.push({ d1, d2, i, k });
    }
  }
  box(gate, 'track_top', 1.7, .03, .05, .8, 2.16, 0, M.iron);
  box(gate, 'track_bot', 1.7, .02, .05, .8, .01, 0, M.iron);

  // ---------- Světla ----------
  const lights = grp(root, 'Lights');
  const lampLight = new THREE.PointLight('#ffc070', 9, 6, 1.6); lampLight.position.set(-.7, 1.1, -1.35); lampLight.castShadow = true; lampLight.shadow.mapSize.set(1024, 1024); lights.add(lampLight);
  const moon = new THREE.DirectionalLight('#7f9cd6', .9); moon.position.set(-3, 5, -6); moon.castShadow = true;
  moon.shadow.camera.left = -7; moon.shadow.camera.right = 7; moon.shadow.camera.top = 7; moon.shadow.camera.bottom = -7; moon.shadow.mapSize.set(1024, 1024); lights.add(moon);
  const tubeLight = new THREE.PointLight('#cfe6ff', 0, 5, 1.8); tubeLight.position.set(0, 2.7, 3.5); lights.add(tubeLight);
  const carLight = new THREE.PointLight('#ffd890', 0, 3.5, 1.8); carLight.position.set(0, 2.0, .9); car.add(carLight);
  const amb = new THREE.HemisphereLight('#4a5a80', '#20160c', .7); lights.add(amb);

  // ---------- Animace (stavový automat výtahu) ----------
  const floorAngle = { S: 0, P: 1, 1: 2, 2: 3, 3: 4 };
  const setNeedle = (f) => { needle.rotation.z = Math.PI / 2 - (f + .5) / 5 * Math.PI; };
  const setGate = (open) => { // open 1 = složená vlevo, 0 = zavřená přes celý otvor
    const width = THREE.MathUtils.lerp(1.6, .18, open), step = width / (N - 1);
    const ang = Math.acos(Math.min(1, step / .6 * 1.0));
    for (const g of gateBars) {
      const x = g.i * step;
      if (g.v) g.v.position.x = x;
      else {
        g.d1.position.x = g.d2.position.x = x + step / 2;
        g.d1.visible = g.d2.visible = g.i < N - 1;
        g.d1.scale.y = g.d2.scale.y = Math.hypot(step, .5) / .6;
        const a = Math.atan2(step, .5); g.d1.rotation.z = a; g.d2.rotation.z = -a;
      }
    }
    return ang;
  };
  const setButtonLit = (n, on) => { const m = buttons[n].material; m.emissive = new THREE.Color(on ? '#ffb040' : '#000'); m.emissiveIntensity = on ? 2 : 0; };
  const state = { name: 'BEZ_PROUDU' };
  // úroveň patra: hráč je ve 3. patře (y=0). Přízemí = -3 * 3.4
  const FLOOR_H = 3.4;
  function setPower(on) {
    tubeLight.intensity = on ? 6 : 0; M.tube.emissiveIntensity = on ? 1.5 : 0;
    carLight.intensity = on ? 5 : 0; M.bulb.emissiveIntensity = on ? 2 : .3;
    globe.material.emissiveIntensity = on ? 2.2 : .4;
  }
  setPower(false); setGate(1); setNeedle(floorAngle['3']);

  const anim = {
    root, state, buttons,
    parts: { car, gate, needle, fuseDoor, door, lampLight, tubeLight, carLight, clock },
    setPower, setGate, setNeedle, setButtonLit,
    /** Ovládání pro preview: t v sekundách. */
    pose(t) {
      // pendl hodin stojí (hodiny nejdou)
      // 0-6 s: průlet kanceláří, 6 s: pojistka -> proud (blikání), 8-10 s mříž se zavře, 10-11 tlačítka 3,2,P, 11-17 jízda dolů
      const flick = t > 6 && t < 7 ? (Math.sin(t * 60) > .2 ? 1 : 0) : (t >= 7 ? 1 : 0);
      setPower(!!flick); state.name = t < 6 ? 'BEZ_PROUDU' : 'PROUD_OK';
      tubeLight.intensity *= 0.85 + .15 * Math.sin(t * 37) * Math.sin(t * 11);
      fuseDoor.rotation.y = -1.2;
      const g = THREE.MathUtils.clamp((t - 8.2) / 1.6, 0, 1);
      setGate(1 - g * g * (3 - 2 * g));
      ['3', '2', 'P'].forEach((n, i) => setButtonLit(n, t > 10 + i * .35 && t < 17.5));
      if (t > 10) state.name = 'ODEMČENO';
      const ride = THREE.MathUtils.clamp((t - 11.2) / 6, 0, 1), e = ride * ride * (3 - 2 * ride);
      car.position.y = -e * 3 * FLOOR_H;
      car.position.x = ride > 0 && ride < 1 ? Math.sin(t * 40) * .004 : 0;
      setNeedle(THREE.MathUtils.lerp(floorAngle['3'], floorAngle['P'], e));
      if (ride > 0 && ride < 1) state.name = 'JEDE'; if (ride >= 1) state.name = 'CÍL';
    }
  };
  return anim;
}
