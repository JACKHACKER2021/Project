// RadioÚstí shared helpers.
import { world, system, ItemStack, GameMode } from "@minecraft/server";
import { REGISTRY } from "../data/registry.js";

export const NS = "radiousti";
export const BLOCKS = REGISTRY.blocks;
export const ITEMS = REGISTRY.items;

/** Six neighbour directions with the block-state suffix used by pipes and cables. */
export const DIRS6 = [
  { k: "n", x: 0, y: 0, z: -1, opp: "s" },
  { k: "s", x: 0, y: 0, z: 1, opp: "n" },
  { k: "e", x: 1, y: 0, z: 0, opp: "w" },
  { k: "w", x: -1, y: 0, z: 0, opp: "e" },
  { k: "u", x: 0, y: 1, z: 0, opp: "d" },
  { k: "d", x: 0, y: -1, z: 0, opp: "u" },
];

/**
 * Rotate a local offset (front = north / -Z) to a world facing.
 * Must match tools/geo.py rot_vec(), which rotates the generated geometry.
 */
export function rotXZ(dir, x, z) {
  switch (dir) {
    case "south": return [-x, -z];
    case "west": return [z, -x];
    case "east": return [-z, x];
    default: return [x, z];
  }
}

export function add(a, b) {
  return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
}

export function posKey(dimId, p) {
  return `${dimId}|${Math.floor(p.x)}|${Math.floor(p.y)}|${Math.floor(p.z)}`;
}

export function parseKey(key) {
  const [d, x, y, z] = key.split("|");
  return { dim: d, x: Number(x), y: Number(y), z: Number(z) };
}

export function dist2(a, b) {
  const dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
  return dx * dx + dy * dy + dz * dz;
}

/** getBlock that never throws (unloaded chunk / out of bounds -> undefined). */
export function blockAt(dim, p) {
  try {
    return dim.getBlock({ x: Math.floor(p.x), y: Math.floor(p.y), z: Math.floor(p.z) });
  } catch {
    return undefined;
  }
}

export function dimOf(id) {
  try {
    return world.getDimension(id);
  } catch {
    return undefined;
  }
}

export function info(typeId) {
  return BLOCKS[typeId];
}

export function isOurs(typeId) {
  return typeId !== undefined && typeId.startsWith(NS + ":");
}

export function stateOf(block, name, fallback = undefined) {
  try {
    const v = block.permutation.getState(name);
    return v === undefined ? fallback : v;
  } catch {
    return fallback;
  }
}

/** Set a block state if it exists and differs. Returns true on change. */
export function setState(block, name, value) {
  try {
    const cur = block.permutation.getState(name);
    if (cur === undefined || cur === value) return false;
    block.setPermutation(block.permutation.withState(name, value));
    return true;
  } catch {
    return false;
  }
}

export function isCreative(player) {
  try {
    return player.getGameMode() === GameMode.Creative;
  } catch {
    return false;
  }
}

export function dropItem(dim, loc, id, count = 1) {
  try {
    dim.spawnItem(new ItemStack(id, count), { x: loc.x + 0.5, y: loc.y + 0.5, z: loc.z + 0.5 });
  } catch (e) {
    console.warn(`[RadioÚstí] drop failed for ${id}: ${e}`);
  }
}

export function sound(dim, loc, id, volume = 1, pitch = 1) {
  try {
    dim.playSound(id, { x: loc.x + 0.5, y: loc.y + 0.5, z: loc.z + 0.5 }, { volume, pitch });
  } catch {
    /* sound missing or dimension unavailable - never fatal */
  }
}

export function heldItem(player) {
  try {
    const inv = player.getComponent("minecraft:inventory");
    return inv?.container?.getItem(player.selectedSlotIndex);
  } catch {
    return undefined;
  }
}

/** Consume `count` of the held item (no-op in creative). */
export function consumeHeld(player, count = 1) {
  if (isCreative(player)) return true;
  const inv = player.getComponent("minecraft:inventory");
  const c = inv?.container;
  if (!c) return false;
  const it = c.getItem(player.selectedSlotIndex);
  if (!it || it.amount < count) return false;
  if (it.amount === count) c.setItem(player.selectedSlotIndex, undefined);
  else {
    it.amount -= count;
    c.setItem(player.selectedSlotIndex, it);
  }
  return true;
}

export function countItem(player, id) {
  const c = player.getComponent("minecraft:inventory")?.container;
  if (!c) return 0;
  let n = 0;
  for (let i = 0; i < c.size; i++) {
    const it = c.getItem(i);
    if (it && it.typeId === id) n += it.amount;
  }
  return n;
}

/** Remove `count` items of `id` from the inventory; returns false (and removes nothing) if not enough. */
export function takeItem(player, id, count = 1) {
  if (isCreative(player)) return true;
  if (countItem(player, id) < count) return false;
  const c = player.getComponent("minecraft:inventory").container;
  let left = count;
  for (let i = 0; i < c.size && left > 0; i++) {
    const it = c.getItem(i);
    if (!it || it.typeId !== id) continue;
    if (it.amount <= left) {
      left -= it.amount;
      c.setItem(i, undefined);
    } else {
      it.amount -= left;
      left = 0;
      c.setItem(i, it);
    }
  }
  return true;
}

export function giveItem(player, id, count = 1) {
  const c = player.getComponent("minecraft:inventory")?.container;
  const stack = new ItemStack(id, count);
  const rest = c ? c.addItem(stack) : stack;
  if (rest) dropItem(player.dimension, player.location, id, rest.amount);
}

export function name(typeId) {
  const b = BLOCKS[typeId] ?? ITEMS[typeId];
  if (b) return b.cs;
  return typeId.replace("minecraft:", "");
}

export function later(fn, ticks = 1) {
  system.runTimeout(() => {
    try {
      fn();
    } catch (e) {
      console.warn(`[RadioÚstí] ${e}\n${e?.stack ?? ""}`);
    }
  }, ticks);
}

export function safe(label, fn) {
  return (...args) => {
    try {
      return fn(...args);
    } catch (e) {
      console.warn(`[RadioÚstí] ${label}: ${e}\n${e?.stack ?? ""}`);
    }
  };
}

export function fmtPos(p) {
  return `${Math.floor(p.x)} ${Math.floor(p.y)} ${Math.floor(p.z)}`;
}
