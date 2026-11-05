// Directional connection detection for pipes, valves and cables.
// A pipe/cable stores six boolean states (n,s,e,w,u,d) plus "joint" and the geometry
// shows the matching arms via bone_visibility, so the visible shape always equals the
// real connection graph used by the network simulation (systems/network.js).
import { NS, BLOCKS, DIRS6, add, blockAt, info } from "../lib/util.js";

/** Fluid families a machine accepts on any face (in addition to meta.family). */
export const MACHINE_FLUIDS = {
  [`${NS}:generator_standard`]: ["oil"],
  [`${NS}:generator_industrial`]: ["gas", "molten"],
  [`${NS}:chemical_analysis_table`]: ["gas"],
};

const VANILLA_FLUID = {
  "minecraft:water": "water",
  "minecraft:flowing_water": "water",
  "minecraft:lava": "molten",
  "minecraft:flowing_lava": "molten",
};

export function isConduit(typeId) {
  const i = BLOCKS[typeId];
  return !!i && (i.kind === "pipe" || i.kind === "valve" || i.kind === "cable");
}

/** Resource family carried by a conduit: water|gas|molten|radioactive|oil|power|data. */
export function familyOf(typeId) {
  return BLOCKS[typeId]?.family;
}

/** Does a non-conduit block accept the given family? */
export function acceptsFamily(typeId, fam) {
  const i = BLOCKS[typeId];
  if (!i) return VANILLA_FLUID[typeId] === fam;
  if (fam === "power") {
    if (i.kind === "reactor_port") return i.family === "power";
    if (i.kind !== "machine") return false;
    return ["generator", "battery", "computer", "server", "station"].includes(i.role);
  }
  if (fam === "data") {
    return i.kind === "machine" || i.kind === "reactor_shell" || i.kind === "reactor_port";
  }
  if (i.kind === "reactor_port") return i.family === fam;
  if (i.kind === "machine") {
    if (i.family === fam) return true;
    return (MACHINE_FLUIDS[typeId] ?? []).includes(fam);
  }
  return false;
}

export function conduitLinks(typeA, typeB) {
  const fa = familyOf(typeA), fb = familyOf(typeB);
  if (!fa) return false;
  if (isConduit(typeB)) return fa === fb;
  return acceptsFamily(typeB, fa);
}

/** Recompute and apply the six connection states of one conduit block. */
export function updateConduit(block) {
  if (!block || !isConduit(block.typeId)) return;
  const dim = block.dimension;
  let perm = block.permutation;
  let changed = false;
  const put = (name, v) => {
    if (perm.getState(name) !== v) {
      perm = perm.withState(name, v);
      changed = true;
    }
  };
  const on = [];
  for (const d of DIRS6) {
    const nb = blockAt(dim, add(block.location, d));
    const c = !!nb && conduitLinks(block.typeId, nb.typeId);
    if (c) on.push(d.k);
    put(`${NS}:${d.k}`, c);
  }
  const straight = on.length === 2 && DIRS6.find((d) => d.k === on[0])?.opp === on[1];
  const joint = on.length >= 3 || (on.length === 2 && !straight);
  if (info(block.typeId).kind !== "valve") put(`${NS}:joint`, joint);
  if (changed) block.setPermutation(perm);
}

/** Update a position and its six neighbours (call after any block change). */
export function updateAround(dim, loc) {
  updateConduit(blockAt(dim, loc));
  for (const d of DIRS6) updateConduit(blockAt(dim, add(loc, d)));
}

/** Directions a conduit is currently connected to (from its states). */
export function connectedDirs(block) {
  const out = [];
  for (const d of DIRS6) {
    try {
      if (block.permutation.getState(`${NS}:${d.k}`) === true) out.push(d);
    } catch {
      /* not a conduit */
    }
  }
  return out;
}
