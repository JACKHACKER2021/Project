// Nuke Bomb: 30-second countdown, a ring of explosions and heavy contamination of the area.
import { world, system } from "@minecraft/server";
import { MessageFormData } from "@minecraft/server-ui";
import { NS, posKey, parseKey, dimOf, blockAt, sound, dist2 } from "../lib/util.js";
import { Logs, Config } from "../lib/store.js";
import { contaminateArea, getDose, setDose, fullHazmat, inBunker } from "./radiation.js";
import { startSmog } from "./environment.js";

const COUNTDOWN = 30;
const armed = new Map(); // key -> end tick

export async function interactNuke(player, block) {
  const key = posKey(block.dimension.id, block.location);
  if (armed.has(key)) {
    const r = await new MessageFormData().title("§4§lATOMOVÁ BOMBA").body("Odpočet běží! Deaktivovat?").button1("§aDeaktivovat").button2("Zavřít").show(player);
    if (r.selection === 0) {
      armed.delete(key);
      world.sendMessage(`§a☢ Atomová bomba na ${block.location.x} ${block.location.y} ${block.location.z} byla deaktivována (${player.name}).`);
    }
    return;
  }
  if (Config.get().nuke === false) {
    player.sendMessage("§7Atomové bomby jsou v tomto světě vypnuté (/scriptevent radiousti:config nuke on).");
    return;
  }
  const r = await new MessageFormData().title("§4§lATOMOVÁ BOMBA")
    .body(`§cPo odpálení zničí okolí a zamoří ho radiací v okruhu 32 bloků.§r\nOdpočet: ${COUNTDOWN} s. Utečte co nejdál a schovejte se pod zem.`)
    .button1("§4ODPÁLIT").button2("Zrušit").show(player);
  if (r.selection !== 0) return;
  armed.set(key, system.currentTick + COUNTDOWN * 20);
  Logs.push("alarms", `ATOMOVÁ BOMBA aktivována na ${block.location.x} ${block.location.y} ${block.location.z} (${player.name}).`);
  world.sendMessage(`§4§l☢ ATOMOVÁ BOMBA AKTIVOVÁNA§r §con ${block.location.x} ${block.location.y} ${block.location.z} – ${COUNTDOWN} sekund!`);
}

function detonate(key) {
  const p = parseKey(key);
  detonateAt(dimOf(p.dim), p);
}

export function detonateAt(dim, p) {
  if (!dim) return;
  for (const pl of world.getAllPlayers()) {
    if (pl.dimension.id === dim.id && dist2(pl.location, p) < 200 * 200) {
      try {
        pl.playSound("radiousti.nuke_blast", { volume: 1 });
      } catch {
        /* ignore */
      }
    }
  }
  const b = blockAt(dim, p);
  if (b?.typeId === `${NS}:nuke_bomb`) b.setType("minecraft:air");
  const c = { x: p.x + 0.5, y: p.y + 0.5, z: p.z + 0.5 };
  flash(dim, p);
  mushroomCloud(dim, c);
  system.runJob(carveCrater(dim, { x: Math.floor(p.x), y: Math.floor(p.y), z: Math.floor(p.z) }, Config.get().craterRadius ?? 11));
  const key = posKey(dim.id, p);
  try {
    dim.createExplosion(c, 12, { breaksBlocks: true, causesFire: true });
  } catch {
    /* explosions disabled */
  }
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2;
    system.runTimeout(() => {
      try {
        dim.createExplosion({ x: c.x + Math.cos(a) * 10, y: c.y, z: c.z + Math.sin(a) * 10 }, 8, { breaksBlocks: true, causesFire: i % 2 === 0 });
      } catch {
        /* ignore */
      }
    }, 4 + i * 2);
  }
  system.runTimeout(() => {
    contaminateArea(dim, p, 32, 2500, 40);
    for (const pl of world.getAllPlayers()) {
      if (pl.dimension.id !== dim.id) continue;
      const d = Math.sqrt(dist2(pl.location, p));
      if (d < 64 && !fullHazmat(pl) && !inBunker(pl)) setDose(pl, getDose(pl) + (64 - d) * 1.5);
      else if (d < 64 && inBunker(pl)) pl.onScreenDisplay.setActionBar("§aBunkr vydržel – jsi v bezpečí.");
    }
    try {
      dim.runCommand("weather rain 9000");
    } catch {
      /* ignore */
    }
    startSmog(6);
  }, 30);
  void key;
  Logs.push("alarms", `!!! JADERNÝ VÝBUCH na ${p.x} ${p.y} ${p.z}.`);
  Logs.push("contamination", `Jaderný výbuch na ${p.x} ${p.y} ${p.z}: zamořen okruh 32 bloků.`);
  world.sendMessage("§4§l☢ JADERNÝ VÝBUCH!§r §cOblast je silně zamořená.");
}

system.runInterval(() => {
  const now = system.currentTick;
  for (const [key, end] of armed) {
    const p = parseKey(key);
    const dim = dimOf(p.dim);
    const b = dim && blockAt(dim, p);
    if (b && b.typeId !== `${NS}:nuke_bomb`) {
      armed.delete(key); // bomb removed
      continue;
    }
    const left = Math.ceil((end - now) / 20);
    if (left <= 0) {
      armed.delete(key);
      detonate(key);
      continue;
    }
    if (dim) sound(dim, p, "radiousti.alarm", 2, left < 10 ? 1.4 : 1);
    for (const pl of world.getAllPlayers()) {
      if (dim && pl.dimension.id === dim.id && dist2(pl.location, p) < 96 * 96) {
        pl.onScreenDisplay.setTitle(`§4☢ ${left}`, { subtitle: "§cATOMOVÁ BOMBA – utečte!", fadeInDuration: 0, stayDuration: 25, fadeOutDuration: 0 });
      }
    }
  }
}, 20);

// ------------------------------------------------------------------ crater, mushroom cloud, flash
const KEEP = new Set(["minecraft:bedrock", "minecraft:barrier", "minecraft:command_block", "minecraft:structure_block"]);

/** Carves a bowl-shaped crater (generator for system.runJob, a few hundred blocks per tick). */
function* carveCrater(dim, c, r) {
  const r2 = r * r;
  let n = 0;
  for (let dy = r; dy >= -Math.ceil(r * 0.6); dy--) {
    for (let dx = -r; dx <= r; dx++) {
      for (let dz = -r; dz <= r; dz++) {
        const d2 = dx * dx + dz * dz + (dy < 0 ? (dy * dy) / 0.36 : dy * dy * 0.25);
        if (d2 > r2) continue;
        const b = blockAt(dim, { x: c.x + dx, y: c.y + dy, z: c.z + dz });
        if (!b || b.isAir || KEEP.has(b.typeId) || b.typeId.startsWith(`${NS}:bunker_`)) continue;
        try {
          b.setType("minecraft:air");
        } catch {
          /* ignore */
        }
        if (++n % 200 === 0) yield;
      }
    }
  }
  // scorched, radioactive rim
  for (let i = 0; i < r * 14; i++) {
    const a = Math.random() * Math.PI * 2, rr = r * (0.55 + Math.random() * 0.5);
    const x = Math.floor(c.x + Math.cos(a) * rr), z = Math.floor(c.z + Math.sin(a) * rr);
    try {
      const top = dim.getTopmostBlock({ x, z });
      if (!top || top.typeId.startsWith(`${NS}:bunker_`)) continue;
      const roll = Math.random();
      top.setType(roll < 0.25 ? `${NS}:radioactive_waste` : roll < 0.6 ? `${NS}:contaminated_stone` : "minecraft:blackstone");
      if (Math.random() < 0.2) dim.getBlock({ x, y: top.location.y + 1, z })?.setType("minecraft:fire");
    } catch {
      /* ignore */
    }
    if (i % 20 === 0) yield;
  }
}

function mushroomCloud(dim, c) {
  for (let i = 0; i < 40; i++) {
    system.runTimeout(() => {
      try {
        dim.spawnParticle(`${NS}:nuke_cloud`, { x: c.x, y: c.y + Math.min(i, 28), z: c.z });
        if (i > 18) dim.spawnParticle(`${NS}:nuke_cap`, { x: c.x, y: c.y + 30, z: c.z });
      } catch {
        /* particles not loaded */
      }
    }, i * 3);
  }
}

function flash(dim, p) {
  for (const pl of world.getAllPlayers()) {
    if (pl.dimension.id !== dim.id || dist2(pl.location, p) > 160 * 160) continue;
    try {
      pl.camera.fade({ fadeColor: { red: 1, green: 1, blue: 0.85 }, fadeTime: { fadeInTime: 0.05, holdTime: 0.6, fadeOutTime: 2.5 } });
    } catch {
      /* camera unavailable */
    }
  }
}

// ------------------------------------------------------------------ air-raid event (atomic bombs falling from the sky)
// /radiousti:atomic_bomb <on|off|strike|status> [minutes]
let raidUntil = 0;

export function isAirRaid() {
  return system.currentTick < raidUntil;
}

function strikeNear(player, delaySec = 20, bombs = 3 + Math.floor(Math.random() * 3)) {
  const dim = player.dimension;
  if (dim.id !== "minecraft:overworld") return false;
  const targets = [];
  for (let i = 0; i < bombs; i++) {
    const a = Math.random() * Math.PI * 2, d = 45 + Math.random() * 70;
    targets.push({ x: Math.floor(player.location.x + Math.cos(a) * d), z: Math.floor(player.location.z + Math.sin(a) * d) });
  }
  const x = targets[0].x, z = targets[0].z;
  raidUntil = system.currentTick + (delaySec + 40) * 20;
  world.sendMessage(`§4§l☢ LETECKÝ POPLACH!§r §cNad RadioÚstí letí ${bombs} atomových bomb – první dopad za ${delaySec} s (např. ${x} ${z}). Do krytu!`);
  for (const pl of world.getAllPlayers()) {
    try {
      pl.playSound("radiousti.siren", { volume: 1 });
    } catch {
      /* ignore */
    }
  }
  for (let t = 0; t < delaySec; t += 4) {
    system.runTimeout(() => {
      for (const pl of world.getAllPlayers()) {
        try {
          pl.playSound("radiousti.siren", { volume: 0.8 });
          pl.onScreenDisplay.setTitle("§4☢ LETECKÝ POPLACH", { subtitle: `§cdopad za ${delaySec - t} s`, fadeInDuration: 0, stayDuration: 40, fadeOutDuration: 10 });
        } catch {
          /* ignore */
        }
      }
    }, t * 20);
  }
  // bombs fall from the sky as entities and explode on impact (staggered)
  targets.forEach((t, i) => {
    system.runTimeout(() => {
      try {
        const top = dim.getTopmostBlock({ x: t.x, z: t.z });
        const y = Math.min(318, (top?.location.y ?? 64) + 70);
        const e = dim.spawnEntity(`${NS}:falling_nuke`, { x: t.x + 0.5, y, z: t.z + 0.5 });
        falling.set(e.id, { dim, at: system.currentTick });
      } catch {
        // unloaded target: explode directly at the surface if possible
        try {
          const top = dim.getTopmostBlock({ x: t.x, z: t.z });
          if (top) detonateAt(dim, { x: t.x, y: top.location.y + 1, z: t.z });
        } catch {
          /* ignore */
        }
      }
    }, Math.max(0, delaySec - 5) * 20 + i * 60);
  });
  return true;
}

export function strikeRandom() {
  const players = world.getAllPlayers().filter((p) => p.dimension.id === "minecraft:overworld");
  if (!players.length) return false;
  return strikeNear(players[Math.floor(Math.random() * players.length)]);
}

// falling bombs: detonate when they hit the ground (or after 15 s)
const falling = new Map(); // entity id -> { dim, at }
system.runInterval(() => {
  for (const [id, f] of falling) {
    const e = world.getEntity(id);
    if (!e || !e.isValid) {
      falling.delete(id);
      continue;
    }
    try {
      e.dimension.spawnParticle("minecraft:campfire_smoke_particle", { x: e.location.x, y: e.location.y + 1.5, z: e.location.z });
    } catch {
      /* ignore */
    }
    const v = e.getVelocity();
    const landed = e.isOnGround || Math.abs(v.y) < 0.01 || system.currentTick - f.at > 300;
    if (landed) {
      const loc = { x: Math.floor(e.location.x), y: Math.floor(e.location.y), z: Math.floor(e.location.z) };
      falling.delete(id);
      try {
        e.remove();
      } catch {
        /* ignore */
      }
      detonateAt(f.dim, loc);
    }
  }
}, 2);

let lastStrike = 0;
system.runInterval(() => {
  const cfg = Config.get();
  if (!cfg.atomicEvent) return;
  const every = Math.max(1, cfg.atomicEveryMinutes ?? 30) * 60 * 20;
  if (lastStrike === 0) lastStrike = system.currentTick;
  const jitter = every <= 1200 ? 1 : 0.7 + Math.random() * 0.6;
  if (system.currentTick - lastStrike >= every * jitter) {
    lastStrike = system.currentTick;
    strikeRandom();
  }
}, 200);

export function atomicCommand(origin, action, minutes) {
  const who = origin.sourceEntity;
  switch (action) {
    case "on":
      Config.set({ atomicEvent: true, atomicEveryMinutes: minutes ?? Config.get().atomicEveryMinutes ?? 30 });
      lastStrike = system.currentTick;
      return `Atomové útoky ZAPNUTY – zhruba každých ${Config.get().atomicEveryMinutes} minut.`;
    case "off":
      Config.set({ atomicEvent: false });
      return "Atomové útoky vypnuty.";
    case "strike":
      if (who && who.typeId === "minecraft:player") strikeNear(/** @type {any} */ (who), 20);
      else strikeRandom();
      return "Letecký poplach vyhlášen – bomba dopadne za 20 s.";
    default: {
      const c = Config.get();
      return `Atomové útoky: ${c.atomicEvent ? "zapnuty" : "vypnuty"}, interval ${c.atomicEveryMinutes ?? 30} min.`;
    }
  }
}
