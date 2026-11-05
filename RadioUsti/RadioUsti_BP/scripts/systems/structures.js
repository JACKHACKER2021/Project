// Multiblock machines/furniture (2x2, 2x2x2, 1x2) and true two-block doors.
import { BlockPermutation } from "@minecraft/server";
import { NS, info, rotXZ, add, blockAt, stateOf, isCreative, dropItem, sound, giveItem } from "../lib/util.js";

const PART = `${NS}:part`;
const DIR = "minecraft:cardinal_direction";

export function partOffset(typeId, part, dir) {
  const o = info(typeId)?.multiblock?.[part];
  if (!o) return { x: 0, y: 0, z: 0 };
  const [x, z] = rotXZ(dir, o[0], o[2]);
  return { x, y: o[1], z };
}

/** Origin (part 0) location of a multiblock from any part block. */
export function originOf(block) {
  const part = stateOf(block, PART, 0);
  const dir = stateOf(block, DIR, "north");
  const o = partOffset(block.typeId, part, dir);
  return { x: block.location.x - o.x, y: block.location.y - o.y, z: block.location.z - o.z };
}

/** World positions of all parts for an origin. */
export function partPositions(typeId, origin, dir) {
  const parts = info(typeId)?.multiblock ?? [[0, 0, 0]];
  return parts.map((_, i) => add(origin, partOffset(typeId, i, dir)));
}

function replaceable(b) {
  if (!b) return false;
  if (b.isAir || b.isLiquid) return true;
  return ["minecraft:short_grass", "minecraft:tall_grass", "minecraft:snow_layer", "minecraft:fern", "minecraft:deadbush"].includes(b.typeId);
}

/** Called after a player placed part 0. Returns true if the full structure was built. */
export function buildMultiblock(player, block) {
  const typeId = block.typeId;
  const dir = stateOf(block, DIR, "north");
  const origin = block.location;
  const pos = partPositions(typeId, origin, dir);
  const dim = block.dimension;
  for (let i = 1; i < pos.length; i++) {
    if (!replaceable(blockAt(dim, pos[i]))) {
      block.setType("minecraft:air");
      if (!isCreative(player)) giveItem(player, typeId, 1);
      player.onScreenDisplay.setActionBar(`§c${info(typeId).cs}: není dost místa (potřeba ${describeSize(typeId)}).`);
      return false;
    }
  }
  for (let i = 1; i < pos.length; i++) {
    const states = { [PART]: i };
    if (info(typeId).rot === "cardinal") states[DIR] = dir;
    blockAt(dim, pos[i])?.setPermutation(BlockPermutation.resolve(typeId, states));
  }
  return true;
}

export function describeSize(typeId) {
  const parts = info(typeId)?.multiblock ?? [[0, 0, 0]];
  const mx = Math.max(...parts.map((p) => p[0])) + 1;
  const my = Math.max(...parts.map((p) => p[1])) + 1;
  const mz = Math.max(...parts.map((p) => p[2])) + 1;
  return `${mx}×${mz} půdorys, výška ${my}`;
}

/** After a part was broken: remove the remaining parts and drop one item (survival). */
export function breakMultiblock(dim, loc, perm, player) {
  const typeId = perm.type.id;
  const part = perm.getState(PART) ?? 0;
  const dir = perm.getState(DIR) ?? "north";
  const o = partOffset(typeId, part, dir);
  const origin = { x: loc.x - o.x, y: loc.y - o.y, z: loc.z - o.z };
  const pos = partPositions(typeId, origin, dir);
  pos.forEach((p, i) => {
    if (i === part) return;
    const b = blockAt(dim, p);
    if (b && b.typeId === typeId && stateOf(b, PART) === i) b.setType("minecraft:air");
  });
  if (!player || !isCreative(player)) dropItem(dim, origin, typeId);
  return origin;
}

/** Integrity check: missing part ids for the structure at origin. */
export function missingParts(dim, typeId, origin, dir) {
  const missing = [];
  partPositions(typeId, origin, dir).forEach((p, i) => {
    const b = blockAt(dim, p);
    if (!b) return; // unloaded: do not judge
    if (b.typeId !== typeId || stateOf(b, PART) !== i) missing.push(i);
  });
  return missing;
}

// ------------------------------------------------------------------ doors

const UPPER = `${NS}:upper`;
const OPEN = `${NS}:open`;

export function buildDoor(player, block) {
  const above = blockAt(block.dimension, add(block.location, { x: 0, y: 1, z: 0 }));
  if (!replaceable(above)) {
    block.setType("minecraft:air");
    if (!isCreative(player)) giveItem(player, block.typeId, 1);
    player.onScreenDisplay.setActionBar("§cDveře potřebují dva bloky volného místa na výšku.");
    return false;
  }
  above.setPermutation(block.permutation.withState(UPPER, true).withState(OPEN, false));
  block.setPermutation(block.permutation.withState(UPPER, false).withState(OPEN, false));
  return true;
}

export function otherHalf(block) {
  const up = stateOf(block, UPPER, false);
  return blockAt(block.dimension, add(block.location, { x: 0, y: up ? -1 : 1, z: 0 }));
}

export function toggleDoor(block) {
  const open = !stateOf(block, OPEN, false);
  const other = otherHalf(block);
  block.setPermutation(block.permutation.withState(OPEN, open));
  if (other && other.typeId === block.typeId) other.setPermutation(other.permutation.withState(OPEN, open));
  sound(block.dimension, block.location, open ? "radiousti.door_open" : "radiousti.door_close");
  return open;
}

export function breakDoor(dim, loc, perm, player) {
  const up = perm.getState(UPPER) ?? false;
  const other = blockAt(dim, add(loc, { x: 0, y: up ? -1 : 1, z: 0 }));
  if (other && other.typeId === perm.type.id) other.setType("minecraft:air");
  if (!player || !isCreative(player)) dropItem(dim, up ? add(loc, { x: 0, y: -1, z: 0 }) : loc, perm.type.id);
}
