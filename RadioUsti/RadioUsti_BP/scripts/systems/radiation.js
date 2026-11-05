// Radiation exposure (configurable game mechanic) and terrain contamination.
//   /scriptevent radiousti:config radiation off|on
//   /scriptevent radiousti:config multiplier 0.5
//   /scriptevent radiousti:config wastespread off|on
import { BlockVolume, BlockPermutation, EquipmentSlot } from "@minecraft/server";
import { NS, BLOCKS, ITEMS, blockAt, dist2, sound } from "../lib/util.js";
import { Machines, Config, Logs } from "../lib/store.js";

import { liquidEffects } from "./liquids.js";
import { isRaining, underSky } from "./environment.js";

export const TOXIC_BLOCKS = Object.entries(BLOCKS).filter(([, v]) => v.toxic).map(([k]) => k);

/** Liverocrystal gas: poisons players without a gas mask within 3 blocks of ore, clusters and gas tanks. */
function toxicTick(p) {
  let near = false;
  try {
    const l = p.location;
    const vol = new BlockVolume({ x: l.x - 3, y: l.y - 2, z: l.z - 3 }, { x: l.x + 3, y: l.y + 3, z: l.z + 3 });
    near = p.dimension.containsBlock(vol, { includeTypes: TOXIC_BLOCKS }, false);
  } catch {
    near = false;
  }
  if (!near) return;
  const masked = p.getComponent("minecraft:equippable")?.getEquipment(EquipmentSlot.Head)?.typeId === `${NS}:gas_mask`;
  if (masked) return;
  try {
    p.addEffect("poison", 50, { amplifier: 0, showParticles: false });
    p.addEffect("nausea", 100, { amplifier: 0, showParticles: false });
  } catch {
    /* ignore */
  }
  p.onScreenDisplay.setActionBar("§9Výpary Liverocrystalu! §fNasaď plynovou masku.");
}

export const RAD_BLOCKS = Object.entries(BLOCKS).filter(([, v]) => v.rad).map(([k]) => k);
const RAD_W = Object.fromEntries(Object.entries(BLOCKS).filter(([, v]) => v.rad).map(([k, v]) => [k, v.rad]));

const CONTAMINATE = {
  "minecraft:grass_block": `${NS}:contaminated_grass`,
  "minecraft:dirt": `${NS}:contaminated_dirt`,
  "minecraft:coarse_dirt": `${NS}:contaminated_dirt`,
  "minecraft:podzol": `${NS}:contaminated_dirt`,
  "minecraft:stone": `${NS}:contaminated_stone`,
  "minecraft:cobblestone": `${NS}:contaminated_stone`,
  "minecraft:andesite": `${NS}:contaminated_stone`,
  "minecraft:diorite": `${NS}:contaminated_stone`,
  "minecraft:granite": `${NS}:contaminated_stone`,
};

/** Weighted radiation level around a position (0 = clean). */
export function radiationAt(dim, pos, r = 5) {
  let level = 0;
  try {
    const vol = new BlockVolume({ x: pos.x - r, y: pos.y - r, z: pos.z - r }, { x: pos.x + r, y: pos.y + r, z: pos.z + r });
    const list = dim.getBlocks(vol, { includeTypes: RAD_BLOCKS }, false);
    for (const loc of list.getBlockLocationIterator()) {
      const b = blockAt(dim, loc);
      if (!b) continue;
      const d = Math.sqrt(dist2(loc, pos));
      level += (RAD_W[b.typeId] ?? 1) / (1 + d);
    }
  } catch {
    /* volume touches unloaded chunks */
  }
  for (const [k, rec] of Machines.all()) {
    if (rec.t !== `${NS}:reactor_core`) continue;
    const [d, x, y, z] = k.split("|");
    if (d !== dim.id) continue;
    const dd = dist2({ x: Number(x), y: Number(y), z: Number(z) }, pos);
    if (dd > 144) continue;
    const src = (rec.running ? 1.5 : 0) + (rec.leak ? 6 : 0) + (rec.status === "CRITICAL" ? 3 : 0);
    level += src / (1 + Math.sqrt(dd));
  }
  return level;
}

function inventoryRadiation(player) {
  let r = 0;
  const c = player.getComponent("minecraft:inventory")?.container;
  if (!c) return 0;
  for (let i = 0; i < c.size; i++) {
    const it = c.getItem(i);
    if (!it) continue;
    const w = ITEMS[it.typeId]?.rad ?? (RAD_W[it.typeId] ? RAD_W[it.typeId] * 0.3 : 0);
    if (w) r += w * Math.min(it.amount, 16) * 0.05;
  }
  return Math.min(r, 2);
}

export function protectionOf(player) {
  let m = 1;
  try {
    const eq = player.getComponent("minecraft:equippable");
    if (eq?.getEquipment(EquipmentSlot.Head)?.typeId === `${NS}:gas_mask`) m *= 0.7;
    if (eq?.getEquipment(EquipmentSlot.Chest)?.typeId === `${NS}:hazmat_suit`) m *= 0.5;
  } catch {
    /* no equipment component */
  }
  return m;
}

export function getDose(player) {
  return Number(player.getDynamicProperty("ru:dose") ?? 0);
}

export function setDose(player, v) {
  player.setDynamicProperty("ru:dose", Math.max(0, Math.min(150, v)));
}

const lastRate = new Map();
export function lastRateOf(player) {
  return lastRate.get(player.id) ?? 0;
}

export function radiationTick(players) {
  const cfg = Config.get();
  for (const p of players) {
    try {
      liquidEffects(p);
      toxicTick(p);
    } catch {
      /* ignore */
    }
    if (!cfg.radiation) {
      lastRate.set(p.id, 0);
      continue;
    }
    const loc = { x: Math.floor(p.location.x), y: Math.floor(p.location.y), z: Math.floor(p.location.z) };
    const rain = cfg.rainRadiation !== false && isRaining() && p.dimension.id === "minecraft:overworld" && underSky(p) ? 0.6 : 0;
    const rate = (radiationAt(p.dimension, loc, 4) + inventoryRadiation(p) + rain) * protectionOf(p) * cfg.radiationMultiplier;
    if (rain > 0 && rate > 0.05) p.onScreenDisplay.setActionBar(`§a☢ Radioaktivní déšť! §f${rate.toFixed(2)} mSv/s – schovej se pod střechu`);
    lastRate.set(p.id, rate);
    let dose = getDose(p);
    dose = rate > 0.05 ? dose + rate : dose - 0.15;
    setDose(p, dose);
    dose = getDose(p);
    if (rate > 0.05) {
      sound(p.dimension, loc, "radiousti.geiger", Math.min(1, 0.3 + rate / 3), 1 + Math.min(rate, 2) * 0.2);
    }
    if ((rate > 0.05 && rain === 0) || (rain === 0 && dose >= 10)) {
      const bar = "§a" + "|".repeat(Math.min(20, Math.round(dose / 5))) + "§8" + "|".repeat(Math.max(0, 20 - Math.round(dose / 5)));
      p.onScreenDisplay.setActionBar(`§e☢ ${rate.toFixed(2)} mSv/s  §fdávka ${dose.toFixed(0)}/150 ${bar}`);
    }
    try {
      if (dose >= 25) p.addEffect("nausea", 120, { amplifier: 0, showParticles: false });
      if (dose >= 50) {
        p.addEffect("weakness", 60, { amplifier: 0, showParticles: false });
        p.addEffect("hunger", 60, { amplifier: 1, showParticles: false });
      }
      if (dose >= 75) p.addEffect("poison", 50, { amplifier: 0, showParticles: false });
      if (dose >= 100) p.addEffect("wither", 50, { amplifier: 0, showParticles: false });
    } catch {
      /* effects unavailable */
    }
  }
}

/** Contaminate random terrain around `c`. */
export function contaminateArea(dim, c, r, attempts, wasteBlocks) {
  let changed = 0;
  for (let i = 0; i < attempts; i++) {
    const p = { x: c.x + rnd(-r, r), y: c.y + rnd(-3, 3), z: c.z + rnd(-r, r) };
    if (dist2(p, c) > r * r) continue;
    const b = blockAt(dim, p);
    const to = b && CONTAMINATE[b.typeId];
    if (to) {
      try {
        b.setPermutation(BlockPermutation.resolve(to));
        changed++;
      } catch {
        /* ignore */
      }
    }
  }
  for (let i = 0; i < wasteBlocks; i++) {
    const p = { x: c.x + rnd(-r, r), y: c.y + rnd(-2, 3), z: c.z + rnd(-r, r) };
    const b = blockAt(dim, p);
    const below = blockAt(dim, { x: p.x, y: p.y - 1, z: p.z });
    if (b?.isAir && below && !below.isAir && !below.isLiquid) {
      try {
        b.setPermutation(BlockPermutation.resolve(`${NS}:radioactive_waste`));
      } catch {
        /* ignore */
      }
    }
  }
  return changed;
}

/** Radioactive waste block tick: slowly contaminates nearby terrain (radius 2). */
export function wasteSpreadTick(block) {
  if (!Config.get().wasteSpread) return;
  contaminateArea(block.dimension, block.location, 2, 1, 0);
}

export function decontaminate(block) {
  const clean = BLOCKS[block.typeId]?.clean;
  if (!clean) return false;
  try {
    block.setPermutation(BlockPermutation.resolve(clean));
  } catch {
    return false;
  }
  Logs.push("contamination", `Dekontaminován blok ${block.location.x} ${block.location.y} ${block.location.z}.`);
  return true;
}

export function countContaminated(dim, pos, r = 8) {
  let n = 0;
  try {
    const vol = new BlockVolume({ x: pos.x - r, y: pos.y - r, z: pos.z - r }, { x: pos.x + r, y: pos.y + r, z: pos.z + r });
    const list = dim.getBlocks(vol, { includeTypes: RAD_BLOCKS }, false);
    for (const _ of list.getBlockLocationIterator()) n++;
  } catch {
    return -1;
  }
  return n;
}

function rnd(a, b) {
  return a + Math.floor(Math.random() * (b - a + 1));
}
