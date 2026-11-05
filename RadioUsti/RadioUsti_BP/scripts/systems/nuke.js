// Nuke Bomb: 30-second countdown, a ring of explosions and heavy contamination of the area.
import { world, system } from "@minecraft/server";
import { MessageFormData } from "@minecraft/server-ui";
import { NS, posKey, parseKey, dimOf, blockAt, sound, dist2 } from "../lib/util.js";
import { Logs, Config } from "../lib/store.js";
import { contaminateArea, getDose, setDose, fullHazmat } from "./radiation.js";
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
      if (d < 64 && !fullHazmat(pl)) setDose(pl, getDose(pl) + (64 - d) * 1.5);
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

// ------------------------------------------------------------------ air-raid event (atomic bombs falling from the sky)
// /radiousti:atomic_bomb <on|off|strike|status> [minutes]
let raidUntil = 0;

export function isAirRaid() {
  return system.currentTick < raidUntil;
}

function strikeNear(player, delaySec = 20) {
  const dim = player.dimension;
  if (dim.id !== "minecraft:overworld") return false;
  const a = Math.random() * Math.PI * 2;
  const d = 45 + Math.random() * 50;
  const x = Math.floor(player.location.x + Math.cos(a) * d), z = Math.floor(player.location.z + Math.sin(a) * d);
  raidUntil = system.currentTick + (delaySec + 40) * 20;
  world.sendMessage(`§4§l☢ LETECKÝ POPLACH!§r §cNad RadioÚstí letí atomová bomba – dopad za ${delaySec} s, směr ${Math.round(x)} ${Math.round(z)}. Do krytu!`);
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
  // falling bomb trail during the last 3 seconds
  for (let i = 0; i < 6; i++) {
    system.runTimeout(() => {
      try {
        const top = dim.getTopmostBlock({ x, z });
        const y = (top?.location.y ?? 64) + 40 - i * 7;
        dim.spawnParticle("minecraft:basic_flame_particle", { x: x + 0.5, y, z: z + 0.5 });
        dim.spawnParticle("minecraft:campfire_smoke_particle", { x: x + 0.5, y: y + 1, z: z + 0.5 });
      } catch {
        /* ignore */
      }
    }, (delaySec - 3) * 20 + i * 10);
  }
  system.runTimeout(() => {
    try {
      const top = dim.getTopmostBlock({ x, z });
      if (!top) return;
      detonateAt(dim, { x, y: top.location.y + 1, z });
    } catch {
      /* unloaded */
    }
  }, delaySec * 20);
  return true;
}

export function strikeRandom() {
  const players = world.getAllPlayers().filter((p) => p.dimension.id === "minecraft:overworld");
  if (!players.length) return false;
  return strikeNear(players[Math.floor(Math.random() * players.length)]);
}

let lastStrike = 0;
system.runInterval(() => {
  const cfg = Config.get();
  if (!cfg.atomicEvent) return;
  const every = Math.max(5, cfg.atomicEveryMinutes ?? 30) * 60 * 20;
  if (lastStrike === 0) lastStrike = system.currentTick;
  if (system.currentTick - lastStrike >= every * (0.7 + Math.random() * 0.6)) {
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
