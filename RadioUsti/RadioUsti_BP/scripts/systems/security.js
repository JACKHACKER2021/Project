// Security system (cameras, tablet, shutter doors and buttons), Zed glass-breaking, barricades,
// decontamination curtains, Zéd infection and Radiak's zombies.
import { world, system, BlockVolume, EntityDamageCause, Player } from "@minecraft/server";
import { ActionFormData, ModalFormData } from "@minecraft/server-ui";
import { NS, BLOCKS, DIRS6, add, blockAt, stateOf, sound, parseKey, dist2, fmtPos } from "../lib/util.js";
import { Machines, Config } from "../lib/store.js";
import { ensureMachine } from "./network.js";
import { toggleDoor } from "./structures.js";
import { getDose, setDose, fullHazmat } from "./radiation.js";

const ZED = `${NS}:irradiated_zed`;
const RADIAK_ZOMBIE = `${NS}:radiak_zombie`;
const ZED_TYPES = [ZED, RADIAK_ZOMBIE, "minecraft:zombie", "minecraft:husk", "minecraft:zombie_villager_v2", "minecraft:drowned"];
const FACE_YAW = { north: 180, south: 0, east: -90, west: 90 };
const FACE_VEC = { north: { x: 0, z: -1 }, south: { x: 0, z: 1 }, east: { x: 1, z: 0 }, west: { x: -1, z: 0 } };

// ------------------------------------------------------------------ cameras
export function cameraRecord(block) {
  const [key, rec] = ensureMachine(block);
  if (rec && !rec.label) {
    const n = [...Machines.all().values()].filter((r) => r.t === `${NS}:security_camera`).length;
    rec.label = `Kamera ${n}`;
    Machines.save(key);
  }
  return [key, rec];
}

export async function renameCamera(player, block) {
  const [key, rec] = cameraRecord(block);
  if (!key) return;
  const r = await new ModalFormData().title("Bezpečnostní kamera").textField("Název kamery", "např. Pennov Theater – jeviště", { defaultValue: rec.label }).show(player);
  if (r.canceled || !r.formValues) return;
  rec.label = String(r.formValues[0] || rec.label).slice(0, 40);
  Machines.save(key);
  player.sendMessage(`§a[Kamera] Pojmenováno: ${rec.label}`);
}

function cameras(player) {
  const out = [];
  for (const [k, rec] of Machines.all()) {
    if (rec.t !== `${NS}:security_camera`) continue;
    const p = parseKey(k);
    if (p.dim !== player.dimension.id) continue;
    out.push({ key: k, rec, pos: p });
  }
  return out.sort((a, b) => (a.rec.label ?? "").localeCompare(b.rec.label ?? "", "cs"));
}

const viewing = new Map(); // player.id -> camera key

function viewCamera(player, cam) {
  const b = blockAt(player.dimension, cam.pos);
  if (!b || b.typeId !== `${NS}:security_camera`) {
    player.sendMessage("§cKamera je zničená nebo v nenačtené oblasti.");
    return;
  }
  const face = stateOf(b, "minecraft:block_face", "north");
  const v = FACE_VEC[face] ?? { x: 0, z: -1 };
  const yaw = FACE_YAW[face] ?? 180;
  const pitch = face === "up" ? -30 : face === "down" ? 80 : 25;
  try {
    player.camera.setCamera("minecraft:free", {
      location: { x: cam.pos.x + 0.5 + v.x * 0.45, y: cam.pos.y + 0.55, z: cam.pos.z + 0.5 + v.z * 0.45 },
      rotation: { x: pitch, y: yaw },
    });
    viewing.set(player.id, cam.key);
    sound(player.dimension, player.location, "radiousti.pc_click", 0.6, 0.7);
    player.onScreenDisplay.setActionBar(`§c● REC §f${cam.rec.label} §7– použij tablet: další kamera / plížení + tablet: konec`);
  } catch (e) {
    player.sendMessage(`§c[Kamera] Pohled nelze přepnout: ${e}`);
  }
}

export function stopViewing(player) {
  if (!viewing.has(player.id)) return false;
  try {
    player.camera.clear();
  } catch {
    /* ignore */
  }
  viewing.delete(player.id);
  player.onScreenDisplay.setActionBar("§7Kamerový systém ukončen.");
  return true;
}

export async function openTablet(player) {
  if (player.isSneaking && stopViewing(player)) return;
  const cams = cameras(player);
  const f = new ActionFormData().title("§lBezpečnostní tablet").body(
    `Kamer v dimenzi: ${cams.length}\n§7Kameru pojmenuješ klepnutím na ni. Pohled ukončíš plížením + použitím tabletu.§r`);
  const acts = [];
  for (const c of cams.slice(0, 24)) {
    const d = Math.round(Math.sqrt(dist2(c.pos, player.location)));
    f.button(`§c●§r ${c.rec.label ?? "Kamera"}\n§7${fmtPos(c.pos)} · ${d} m`);
    acts.push(() => viewCamera(player, c));
  }
  f.button("§2Otevřít bezpečnostní dveře (32 m)");
  acts.push(() => player.sendMessage(`§a[Tablet] Otevřeno dveří: ${setDoorsNear(player.dimension, player.location, 32, true)}`));
  f.button("§4Zavřít bezpečnostní dveře (32 m)");
  acts.push(() => player.sendMessage(`§c[Tablet] Zavřeno dveří: ${setDoorsNear(player.dimension, player.location, 32, false)}`));
  if (viewing.has(player.id)) {
    f.button("§8Ukončit sledování");
    acts.push(() => stopViewing(player));
  }
  const r = await f.show(player);
  if (r.canceled || r.selection === undefined) return;
  acts[r.selection]?.();
}

world.afterEvents.playerLeave.subscribe((ev) => viewing.delete(ev.playerId));
world.afterEvents.entityHurt.subscribe((ev) => {
  if (ev.hurtEntity instanceof Player && viewing.has(ev.hurtEntity.id)) {
    stopViewing(ev.hurtEntity);
    ev.hurtEntity.onScreenDisplay.setActionBar("§cNěco tě napadlo – kamera vypnuta!");
  }
});

// ------------------------------------------------------------------ security doors + buttons
const SECURITY_DOORS = Object.entries(BLOCKS).filter(([, v]) => v.kind === "door" && v.security).map(([k]) => k);

/** Open/close all security & barricaded doors in range. Returns how many doors changed. */
export function setDoorsNear(dim, pos, r, open) {
  let n = 0;
  try {
    const vol = new BlockVolume({ x: pos.x - r, y: pos.y - 4, z: pos.z - r }, { x: pos.x + r, y: pos.y + 4, z: pos.z + r });
    for (const loc of dim.getBlocks(vol, { includeTypes: SECURITY_DOORS }, false).getBlockLocationIterator()) {
      const b = blockAt(dim, loc);
      if (!b || stateOf(b, `${NS}:upper`, false)) continue;
      if (stateOf(b, `${NS}:open`, false) !== open) {
        toggleDoor(b);
        n++;
      }
    }
  } catch {
    /* range touches unloaded chunks */
  }
  return n;
}

export function pressDoorButton(block) {
  // decide by the nearest security door: if it is open -> close all, else open all
  let open = true;
  try {
    const vol = new BlockVolume(add(block.location, { x: -8, y: -3, z: -8 }), add(block.location, { x: 8, y: 3, z: 8 }));
    for (const loc of block.dimension.getBlocks(vol, { includeTypes: SECURITY_DOORS }, false).getBlockLocationIterator()) {
      const b = blockAt(block.dimension, loc);
      if (b) {
        open = !stateOf(b, `${NS}:open`, false);
        break;
      }
    }
  } catch {
    /* ignore */
  }
  sound(block.dimension, block.location, "radiousti.pc_click", 1, 0.6);
  return { open, n: setDoorsNear(block.dimension, block.location, 8, open) };
}

// ------------------------------------------------------------------ Zeds break glass, barricades protect
const GLASS = new Set(["minecraft:glass", "minecraft:glass_pane", "minecraft:tinted_glass", `${NS}:old_glass`, `${NS}:help_glass`]);
for (const c of ["white", "orange", "magenta", "light_blue", "yellow", "lime", "pink", "gray", "light_gray", "cyan", "purple", "blue", "brown", "green", "red", "black"]) {
  GLASS.add(`minecraft:${c}_stained_glass`);
  GLASS.add(`minecraft:${c}_stained_glass_pane`);
}
const PROTECT = new Set([`${NS}:window_barricade`, `${NS}:barricade`, `${NS}:barricaded_door`]);

function protectedGlass(b) {
  for (const d of DIRS6) {
    const nb = blockAt(b.dimension, add(b.location, d));
    if (nb && PROTECT.has(nb.typeId)) return true;
  }
  return false;
}

function zedTick() {
  const seen = new Set();
  for (const p of world.getAllPlayers()) {
    let zeds = [];
    try {
      zeds = p.dimension.getEntities({ location: p.location, maxDistance: 40, families: ["zombie"] });
    } catch {
      continue;
    }
    for (const z of zeds) {
      if (seen.has(z.id) || !z.isValid) continue;
      seen.add(z.id);
      const l = { x: Math.floor(z.location.x), y: Math.floor(z.location.y), z: Math.floor(z.location.z) };
      // break nearby unprotected glass (our Zeds always, vanilla zombies rarely)
      const chance = z.typeId === ZED || z.typeId === RADIAK_ZOMBIE ? 0.35 : 0.08;
      for (const d of DIRS6.slice(0, 4)) {
        for (const dy of [0, 1]) {
          const b = blockAt(z.dimension, { x: l.x + d.x, y: l.y + dy, z: l.z + d.z });
          if (!b || !GLASS.has(b.typeId) || Math.random() > chance) continue;
          if (protectedGlass(b)) continue;
          b.setType("minecraft:air");
          sound(z.dimension, b.location, "random.glass", 1);
        }
        // barricaded doors push Zeds back
        const db = blockAt(z.dimension, { x: l.x + d.x, y: l.y, z: l.z + d.z });
        if (db?.typeId === `${NS}:barricaded_door`) {
          try {
            z.applyKnockback({ x: -d.x * 0.8, z: -d.z * 0.8 }, 0.2);
          } catch {
            /* ignore */
          }
        }
      }
      // Radiak's zombies radiate
      if (z.typeId === RADIAK_ZOMBIE) {
        try {
          z.dimension.spawnParticle(`${NS}:radiation_mote`, { x: z.location.x, y: z.location.y + 1.2, z: z.location.z });
        } catch {
          /* ignore */
        }
        for (const pl of world.getAllPlayers()) {
          if (pl.dimension.id === z.dimension.id && dist2(pl.location, z.location) < 16 && !fullHazmat(pl)) setDose(pl, getDose(pl) + 1.5);
        }
      }
    }
  }
}

// ------------------------------------------------------------------ Radiak's reactor slime
function slimeTick() {
  for (const p of world.getAllPlayers()) {
    let slimes = [];
    try {
      slimes = p.dimension.getEntities({ location: p.location, maxDistance: 6, type: `${NS}:radiak_slime` });
    } catch {
      continue;
    }
    for (const s of slimes) {
      try {
        s.dimension.spawnParticle(`${NS}:radiation_mote`, { x: s.location.x, y: s.location.y + 0.6, z: s.location.z });
      } catch {
        /* ignore */
      }
      if (!fullHazmat(p) && dist2(p.location, s.location) < 6.25) {
        setDose(p, getDose(p) + 4);
        p.onScreenDisplay.setActionBar(`§a☢ Reaktorový sliz tě ozařuje! Dávka ${getDose(p).toFixed(0)}`);
      }
    }
  }
}

// ------------------------------------------------------------------ decontamination curtain
function curtainTick() {
  for (const p of world.getAllPlayers()) {
    for (const dy of [0, 1]) {
      const b = blockAt(p.dimension, { x: p.location.x, y: p.location.y + dy, z: p.location.z });
      if (b?.typeId === `${NS}:decontamination_curtain`) {
        const before = getDose(p);
        setDose(p, before - 6);
        cureStep(p, 10);
        if (before > 0.5) p.onScreenDisplay.setActionBar(`§bDekontaminace… dávka ${getDose(p).toFixed(0)}`);
        try {
          p.dimension.spawnParticle("minecraft:water_splash_particle", { x: p.location.x, y: p.location.y + 1.8, z: p.location.z });
        } catch {
          /* ignore */
        }
        break;
      }
    }
  }
}

// ------------------------------------------------------------------ Zéd infection
// Bites from zombies may infect. Stages by time: I (0-3 min) nausea, II (3-6 min) weakness and
// slowness, III (6+ min) damage. Death while infected rises as an Irradiated Zed. Cure: Zed Antibody Serum.
const INF = "ru:infection";

export function infection(p) {
  return Number(p.getDynamicProperty(INF) ?? 0);
}

export function setInfection(p, v) {
  p.setDynamicProperty(INF, Math.max(0, v));
}

export function cureStep(p, cycles) {
  const v = infection(p);
  if (v > 0) setInfection(p, v - cycles);
}

world.afterEvents.entityHitEntity.subscribe((ev) => {
  const z = ev.damagingEntity, p = ev.hitEntity;
  if (!z || !(p instanceof Player) || !ZED_TYPES.includes(z.typeId) || fullHazmat(p)) return;
  if (z.typeId === RADIAK_ZOMBIE) {
    setDose(p, getDose(p) + 15);
    p.onScreenDisplay.setActionBar(`§a☢ Kousnutí Radiakovy zombie! Dávka ${getDose(p).toFixed(0)}`);
  }
  if (Config.get().infection === false || infection(p) > 0) return;
  const chance = z.typeId === RADIAK_ZOMBIE ? 0.4 : z.typeId === ZED ? 0.25 : 0.1;
  if (Math.random() < chance) {
    setInfection(p, 1);
    p.sendMessage("§2☣ Byl jsi nakažen Zéd nákazou! §7Najdi sérum s protilátkami Zed.");
  }
});

function infectionTick() {
  for (const p of world.getAllPlayers()) {
    const v = infection(p);
    if (!v) continue;
    setInfection(p, v + 1); // +1 per 2 s
    const stage = v < 90 ? 1 : v < 180 ? 2 : 3;
    try {
      if (stage >= 1 && Math.random() < 0.3) p.addEffect("nausea", 100, { amplifier: 0, showParticles: false });
      if (stage >= 2) {
        p.addEffect("weakness", 60, { amplifier: 0, showParticles: false });
        p.addEffect("slowness", 60, { amplifier: 0, showParticles: false });
      }
      if (stage >= 3) p.applyDamage(2, { cause: EntityDamageCause.magic });
    } catch {
      /* ignore */
    }
    p.onScreenDisplay.setTitle(" ", { subtitle: `§2☣ Zéd nákaza – fáze ${["", "I", "II", "III"][stage]}`, fadeInDuration: 0, stayDuration: 30, fadeOutDuration: 10 });
  }
}

world.afterEvents.entityDie.subscribe((ev) => {
  const p = ev.deadEntity;
  if (!(p instanceof Player) || !infection(p)) return;
  const loc = p.location;
  setInfection(p, 0);
  try {
    p.dimension.spawnEntity(ZED, loc);
    world.sendMessage(`§2☣ ${p.name} podlehl Zéd nákaze a povstal jako Zed.`);
  } catch {
    /* ignore */
  }
});

export function cureInfection(p) {
  if (!infection(p)) return false;
  setInfection(p, 0);
  p.sendMessage("§aZéd nákaza vyléčena sérem s protilátkami.");
  return true;
}

system.runInterval(() => {
  try {
    zedTick();
    slimeTick();
    curtainTick();
    infectionTick();
  } catch (e) {
    console.warn(`[RadioÚstí] security: ${e}`);
  }
}, 40);
