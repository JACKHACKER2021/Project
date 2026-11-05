// Pseudo-liquids (blood and oils). Bedrock add-ons cannot register real fluids, so these are
// non-solid translucent blocks with a "level" state (0 = source, 1..4 = flowing) that a block tick
// spreads downhill and sideways, plus custom buckets to pick them up and pour them.
import { BlockPermutation, ItemStack } from "@minecraft/server";
import { NS, BLOCKS, add, blockAt, stateOf, isCreative } from "../lib/util.js";

const LEVEL = `${NS}:level`;
const SIDES = [{ x: 1, y: 0, z: 0 }, { x: -1, y: 0, z: 0 }, { x: 0, y: 0, z: 1 }, { x: 0, y: 0, z: -1 }];
const MAX_LEVEL = 4;

export function isLiquid(typeId) {
  return BLOCKS[typeId]?.kind === "liquid";
}

function put(block, typeId, level) {
  try {
    block.setPermutation(BlockPermutation.resolve(typeId, { [LEVEL]: level }));
  } catch {
    /* ignore */
  }
}

/** One flow step for a liquid block (called from its tick component every 10 game ticks). */
export function liquidTick(block) {
  const t = block.typeId;
  const lvl = stateOf(block, LEVEL, 0);
  const dim = block.dimension;
  const above = blockAt(dim, add(block.location, { x: 0, y: 1, z: 0 }));
  // flowing liquid without a feeder dries out
  if (lvl > 0) {
    let fed = above?.typeId === t;
    if (!fed) {
      for (const d of SIDES) {
        const nb = blockAt(dim, add(block.location, d));
        if (nb?.typeId === t && stateOf(nb, LEVEL, 0) < lvl) {
          fed = true;
          break;
        }
      }
    }
    if (!fed) {
      block.setType("minecraft:air");
      return;
    }
  }
  const below = blockAt(dim, add(block.location, { x: 0, y: -1, z: 0 }));
  if (below && below.isAir) {
    put(below, t, 1); // falls; a falling column keeps spreading where it lands
    return;
  }
  if (below?.typeId === t && stateOf(below, LEVEL, 0) > 1) {
    put(below, t, 1);
    return;
  }
  if (lvl >= MAX_LEVEL) return;
  for (const d of SIDES) {
    const nb = blockAt(dim, add(block.location, d));
    if (!nb) continue;
    if (nb.isAir) put(nb, t, lvl + 1);
    else if (nb.typeId === t && stateOf(nb, LEVEL, 0) > lvl + 1) put(nb, t, lvl + 1);
  }
}

const FACE = { Up: { x: 0, y: 1, z: 0 }, Down: { x: 0, y: -1, z: 0 }, North: { x: 0, y: 0, z: -1 },
  South: { x: 0, y: 0, z: 1 }, East: { x: 1, y: 0, z: 0 }, West: { x: -1, y: 0, z: 0 } };

function swapHeld(player, id) {
  if (isCreative(player)) return;
  const c = player.getComponent("minecraft:inventory")?.container;
  if (!c) return;
  const slot = player.selectedSlotIndex;
  const it = c.getItem(slot);
  if (!it) return;
  if (it.amount > 1) {
    it.amount -= 1;
    c.setItem(slot, it);
    const rest = c.addItem(new ItemStack(id, 1));
    if (rest) player.dimension.spawnItem(rest, player.location);
  } else {
    c.setItem(slot, new ItemStack(id, 1));
  }
}

/** Pour a liquid bucket onto the face of `block`. Returns true if handled. */
export function pourBucket(player, block, face, bucketId) {
  const liquidId = Object.entries(BLOCKS).find(([, v]) => v.bucket === bucketId)?.[0];
  if (!liquidId) return false;
  const target = isLiquid(block.typeId) ? block : blockAt(block.dimension, add(block.location, FACE[face] ?? FACE.Up));
  if (!target) return false;
  if (!(target.isAir || (isLiquid(target.typeId) && stateOf(target, LEVEL, 0) > 0))) {
    player.onScreenDisplay.setActionBar("§cSem nelze vylít.");
    return true;
  }
  put(target, liquidId, 0);
  swapHeld(player, "minecraft:bucket");
  return true;
}

/** Fill an empty vanilla bucket from a liquid source. Returns true if handled. */
export function fillBucket(player, block) {
  if (!isLiquid(block.typeId) || stateOf(block, LEVEL, 0) !== 0) return false;
  const bucket = BLOCKS[block.typeId].bucket;
  block.setType("minecraft:air");
  swapHeld(player, bucket);
  return true;
}

/** Effects for entities standing in a liquid (players only, called every 2 s). */
export function liquidEffects(player) {
  const p = player.location;
  for (const dy of [0, 1]) {
    const b = blockAt(player.dimension, { x: p.x, y: p.y + dy, z: p.z });
    const i = b && BLOCKS[b.typeId];
    if (!i || i.kind !== "liquid") continue;
    try {
      player.addEffect("slowness", 50, { amplifier: 1, showParticles: false });
      if (i.effect === "liverocrystal") {
        const masked = player.getComponent("minecraft:equippable")?.getEquipment("Head")?.typeId === `${NS}:gas_mask`;
        if (!masked) {
          player.addEffect("nausea", 160, { amplifier: 0, showParticles: false });
          player.addEffect("poison", 60, { amplifier: 1, showParticles: false });
          player.onScreenDisplay.setActionBar("§9Tekutý Liverocrystal ti prosakuje do těla!");
        }
      } else if (i.effect && i.effect !== "slowness" && i.effect !== "radiation") {
        player.addEffect(i.effect, 60, { amplifier: 0, showParticles: false });
      }
    } catch {
      /* ignore */
    }
    return i;
  }
  return undefined;
}
