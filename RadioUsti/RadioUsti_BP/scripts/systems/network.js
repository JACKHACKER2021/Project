// Machine registry + simplified resource networks.
//
// Model (documented in README "Sítě a stroje"):
//  * Power: generators produce units per 2-second cycle; consumers demand units.
//    A power network = machines joined by power cables. Supply >= demand -> all consumers powered.
//    Batteries (lab power unit, server UPS) store surplus and cover deficits. Backup generators only
//    run when the rest of the network cannot cover the demand. Damaged cables do not transmit.
//  * Fluids: pipes of one family form a network; closed valves cut it. Machines pull discrete units
//    (gas from tanks, oil canisters from barrels, waste pushed into containers). Water/lava are
//    "infinite" sources when a pump/pipe touches a vanilla source. No fluid is rendered flowing.
//  * Data: network cables join computers, servers and any machine for monitoring.
import { world, system, BlockPermutation } from "@minecraft/server";
import { NS, DIRS6, add, posKey, parseKey, blockAt, dimOf, info, stateOf, setState, sound, dist2, dropItem } from "../lib/util.js";
import { Machines, Logs } from "../lib/store.js";
import { isConduit, familyOf, acceptsFamily } from "./connections.js";
import { originOf, partPositions, missingParts, breakMultiblock } from "./structures.js";

export const CYCLE_TICKS = 40;
const MAX_CONDUITS = 512;
const MAX_POWER_COST = 160;

export function machineKeyForBlock(block) {
  const i = info(block.typeId);
  if (!i) return undefined;
  if (i.kind === "reactor_port" || (i.kind === "reactor_shell")) {
    const core = findCoreNear(block.dimension, block.location);
    return core ? posKey(block.dimension.id, core) : undefined;
  }
  if (i.kind !== "machine" && i.kind !== "light" && i.kind !== "alarm" && i.kind !== "indicator") return undefined;
  const o = i.multiblock ? originOf(block) : block.location;
  return posKey(block.dimension.id, o);
}

export function findCoreNear(dim, p) {
  for (let dx = -1; dx <= 1; dx++)
    for (let dy = -1; dy <= 1; dy++)
      for (let dz = -1; dz <= 1; dz++) {
        if (!dx && !dy && !dz) continue;
        const q = { x: p.x + dx, y: p.y + dy, z: p.z + dz };
        const b = blockAt(dim, q);
        if (b?.typeId === `${NS}:reactor_core`) return q;
      }
  return undefined;
}

/** Create the machine record if missing. Returns [key, record]. */
export function ensureMachine(block) {
  const key = machineKeyForBlock(block);
  if (!key) return [undefined, undefined];
  let rec = Machines.get(key);
  if (!rec) {
    const p = parseKey(key);
    const ob = blockAt(block.dimension, p) ?? block;
    rec = defaultRecord(ob.typeId);
    rec.dir = stateOf(ob, "minecraft:cardinal_direction", "north");
    Machines.set(key, rec);
  }
  return [key, rec];
}

export function defaultRecord(typeId) {
  const i = info(typeId) ?? {};
  const r = { t: typeId, on: true, powered: false };
  if (i.role === "generator") Object.assign(r, { fuel: 0, running: false, output: 0 });
  if (i.role === "battery") Object.assign(r, { charge: 0 });
  if (i.role === "tank" && i.family === "gas") r.gas = 0;
  if (i.role === "tank" && i.family === "oil") r.amount = 0;
  if (i.role === "waste_sink") r.waste = 0;
  if (i.role === "station") r.charges = 0;
  if (i.role === "reactor") Object.assign(r, { fuel: 0, burn: 0, heat: 0, waste: 0, running: false, status: "OFF", protect: true });
  if (i.kind === "light") r.manual = false;
  if (i.kind === "alarm") Object.assign(r, { silencedUntil: 0, test: 0 });
  return r;
}

export function unregisterAt(dim, loc, typeId) {
  const i = info(typeId);
  if (!i) return;
  const key = posKey(dim.id, loc);
  if (Machines.get(key)) Machines.delete(key);
}

// ------------------------------------------------------------------ graph scan

/**
 * Breadth-first scan of a conduit network of `family` starting from the faces of `parts`.
 * Returns machines (keys), conduit count, closed valves, damaged cables, vanilla sources and ports.
 */
export function scanNetwork(dim, parts, family) {
  const seen = new Set();
  const partSet = new Set(parts.map((p) => posKey(dim.id, p)));
  const res = { machines: new Set(), conduits: 0, closedValves: 0, damaged: 0, vanilla: new Set(), ports: [], cost: 0, truncated: false };
  const queue = [];
  const visitNeighbour = (p, fromConduit) => {
    const k = posKey(dim.id, p);
    if (seen.has(k) || partSet.has(k)) return;
    const b = blockAt(dim, p);
    if (!b) return;
    if (isConduit(b.typeId)) {
      if (familyOf(b.typeId) !== family) return;
      seen.add(k);
      queue.push(b);
      return;
    }
    if (!fromConduit) return;
    if (!acceptsFamily(b.typeId, family)) return;
    seen.add(k);
    const i = info(b.typeId);
    if (!i) {
      res.vanilla.add(b.typeId);
      return;
    }
    if (i.kind === "reactor_port") res.ports.push({ type: b.typeId, pos: b.location });
    const mk = machineKeyForBlock(b);
    if (mk) {
      ensureMachine(b);
      res.machines.add(mk);
    }
  };
  for (const p of parts) for (const d of DIRS6) visitNeighbour(add(p, d), false);
  while (queue.length) {
    const b = queue.shift();
    const i = info(b.typeId);
    res.conduits++;
    if (res.conduits > MAX_CONDUITS) {
      res.truncated = true;
      break;
    }
    if (i.kind === "valve" && stateOf(b, `${NS}:open`, true) === false) {
      res.closedValves++;
      continue; // a closed valve stops the flow here
    }
    if (i.damaged) {
      res.damaged++;
      continue; // damaged cables do not transmit
    }
    res.cost += Math.max(0, i.cost ?? 1);
    if (family === "power" && res.cost > MAX_POWER_COST) {
      res.truncated = true;
      continue;
    }
    for (const d of DIRS6) visitNeighbour(add(b.location, d), true);
  }
  return res;
}

/** All block positions occupied by the machine with this key (multiblock parts or reactor shell). */
export function machineParts(key, rec) {
  const p = parseKey(key);
  const i = info(rec.t) ?? {};
  if (i.multiblock) return partPositions(rec.t, p, rec.dir ?? "north");
  if (i.role === "reactor") {
    const out = [];
    for (let dx = -1; dx <= 1; dx++)
      for (let dy = -1; dy <= 1; dy++) for (let dz = -1; dz <= 1; dz++) out.push({ x: p.x + dx, y: p.y + dy, z: p.z + dz });
    return out;
  }
  return [p];
}

export function partsForFamily(key, rec, family) {
  // reactor: only the matching port blocks connect
  if (info(rec.t)?.role === "reactor") {
    const p = parseKey(key);
    const dim = dimOf(p.dim);
    const ports = [];
    for (const q of machineParts(key, rec)) {
      const b = blockAt(dim, q);
      const bi = b && info(b.typeId);
      if (!bi) continue;
      if (bi.kind === "reactor_port" && bi.family === family) ports.push(q);
      if (family === "data" && (bi.kind === "reactor_shell" || bi.kind === "reactor_port")) ports.push(q);
    }
    return ports;
  }
  return machineParts(key, rec);
}

export function networkOf(key, rec, family) {
  const p = parseKey(key);
  const dim = dimOf(p.dim);
  if (!dim) return undefined;
  return scanNetwork(dim, partsForFamily(key, rec, family), family);
}

// ------------------------------------------------------------------ fluid helpers

export function pullOil(key, rec, oilType) {
  const net = networkOf(key, rec, "oil");
  if (!net) return false;
  for (const mk of net.machines) {
    const m = Machines.get(mk);
    if (m && info(m.t)?.oil === oilType && (m.amount ?? 0) > 0) {
      m.amount--;
      Machines.save(mk);
      return true;
    }
  }
  return false;
}

export function pullGas(key, rec, units) {
  const net = networkOf(key, rec, "gas");
  if (!net) return false;
  for (const mk of net.machines) {
    const m = Machines.get(mk);
    if (m && m.t === `${NS}:gas_tank` && (m.gas ?? 0) >= units) {
      m.gas -= units;
      Machines.save(mk);
      return true;
    }
  }
  return false;
}

export function hasMolten(key, rec) {
  const net = networkOf(key, rec, "molten");
  return !!net && (net.vanilla.has("minecraft:lava") || net.vanilla.has("minecraft:flowing_lava"));
}

export function waterSource(net) {
  if (!net) return false;
  if (net.vanilla.has("minecraft:water") || net.vanilla.has("minecraft:flowing_water")) return true;
  for (const mk of net.machines) {
    const m = Machines.get(mk);
    if (m && m.t === `${NS}:water_pump` && m.ok) return true;
  }
  return false;
}

// ------------------------------------------------------------------ cycle

const hooks = { beforePower: [], afterPower: [] };
export function onCycle(phase, fn) {
  hooks[phase].push(fn);
}

function validate(key, rec) {
  const p = parseKey(key);
  const dim = dimOf(p.dim);
  if (!dim) return undefined;
  const b = blockAt(dim, p);
  if (!b) return undefined; // unloaded - keep record
  const i = info(rec.t);
  if (b.typeId !== rec.t) {
    // origin block is gone (explosion, piston, command): clean up orphaned parts and refund once
    if (i?.multiblock) {
      let removed = 0;
      partPositions(rec.t, p, rec.dir ?? "north").forEach((q, idx) => {
        const pb = blockAt(dim, q);
        if (pb && pb.typeId === rec.t && stateOf(pb, `${NS}:part`) === idx) {
          pb.setType("minecraft:air");
          removed++;
        }
      });
      if (removed) dropItem(dim, p, rec.t);
    }
    Machines.delete(key);
    return undefined;
  }
  if (i?.multiblock) {
    const miss = missingParts(dim, rec.t, p, rec.dir ?? "north");
    if (miss.length) {
      // structure damaged by an explosion, piston or command: remove it safely and refund
      breakMultiblock(dim, p, b.permutation, undefined);
      b.setType("minecraft:air");
      Machines.delete(key);
      Logs.push("alarms", `${i.cs} na ${p.x} ${p.y} ${p.z} byl poškozen a rozebrán (chyběly části ${miss.join(", ")}).`);
      return undefined;
    }
  }
  return { dim, block: b, info: i, pos: p };
}

export function setActive(ctx, active) {
  if (!ctx) return;
  const parts = ctx.info?.multiblock ? partPositions(ctx.block.typeId, ctx.pos, stateOf(ctx.block, "minecraft:cardinal_direction", "north")) : [ctx.pos];
  for (const q of parts) {
    const b = blockAt(ctx.dim, q);
    if (b && b.typeId === ctx.block.typeId) setState(b, `${NS}:active`, active);
  }
}

let cycleNo = 0;
export function getCycle() {
  return cycleNo;
}

export const live = new Map(); // key -> { ctx } for this cycle

function runCycle() {
  cycleNo++;
  live.clear();
  for (const [key, rec] of Machines.all()) {
    const ctx = validate(key, rec);
    if (ctx) live.set(key, ctx);
  }
  for (const fn of hooks.beforePower) fn(live);
  powerStep();
  for (const fn of hooks.afterPower) fn(live);
}

function demandOf(rec) {
  const i = info(rec.t) ?? {};
  if (rec.on === false) return 0;
  return i.demand ?? 0;
}

function generatorStep(key, rec, ctx) {
  const i = ctx.info;
  rec.output = 0;
  const want = rec.on !== false;
  if (!want) {
    rec.running = false;
    return;
  }
  switch (rec.t) {
    case `${NS}:generator_standard`:
      if ((rec.fuel ?? 0) <= 0 && pullOil(key, rec, "industrial")) rec.fuel = 60;
      if ((rec.fuel ?? 0) > 0) {
        rec.fuel--;
        rec.running = true;
        rec.output = i.output;
      } else rec.running = false;
      break;
    case `${NS}:generator_industrial`:
      if (hasMolten(key, rec)) {
        rec.running = true;
        rec.source = "molten";
        rec.output = i.output;
      } else if (pullGas(key, rec, 1)) {
        rec.running = true;
        rec.source = "gas";
        rec.output = i.output;
      } else {
        rec.running = false;
        rec.source = "none";
      }
      break;
    case `${NS}:generator_nuclear`:
      rec.running = !!rec.reactorFeed;
      rec.output = rec.running ? i.output : 0;
      break;
    default:
      break; // backup generator handled in powerStep
  }
}

function powerStep() {
  const visited = new Set();
  for (const [key, ctx] of live) {
    const rec = Machines.get(key);
    const i = ctx.info;
    if (!i || i.kind !== "machine" || visited.has(key)) continue;
    if (!["generator", "battery", "computer", "server", "station", "reactor"].includes(i.role)) continue;
    // reactor feeds nuclear generators on the network of its power port
    const net = networkOf(key, rec, "power");
    const members = [key, ...(net ? [...net.machines] : [])].filter((k, idx, arr) => arr.indexOf(k) === idx);
    members.forEach((k) => visited.add(k));
    const recs = members.map((k) => [k, Machines.get(k)]).filter(([, r]) => !!r);
    const reactorRunning = recs.some(([, r]) => info(r.t)?.role === "reactor" && r.running);
    let supply = 0, demand = 0;
    for (const [k, r] of recs) {
      const ri = info(r.t);
      const c = live.get(k);
      if (!c) continue;
      if (ri.role === "generator") {
        if (r.t === `${NS}:generator_nuclear`) r.reactorFeed = reactorRunning;
        if (!ri.backup) {
          generatorStep(k, r, c);
          supply += r.output ?? 0;
        }
      } else demand += demandOf(r);
    }
    // backup generators: only when the main supply is insufficient
    for (const [k, r] of recs) {
      const ri = info(r.t);
      if (!ri?.backup || !live.get(k)) continue;
      r.output = 0;
      r.running = false;
      if (r.on !== false && supply < demand && (r.fuel ?? 0) > 0) {
        r.fuel--;
        r.running = true;
        r.output = ri.output;
        supply += ri.output;
      }
    }
    // batteries
    let deficit = demand - supply;
    for (const [k, r] of recs) {
      const ri = info(r.t);
      if (ri?.role !== "battery" || !live.get(k)) continue;
      if (deficit > 0 && r.on !== false) {
        const d = Math.min(ri.rate, r.charge ?? 0, deficit);
        r.charge -= d;
        deficit -= d;
        supply += d;
        r.flow = -d;
      } else if (deficit < 0) {
        const c = Math.min(ri.rate, ri.capacity - (r.charge ?? 0), -deficit);
        r.charge = (r.charge ?? 0) + c;
        deficit += c;
        r.flow = c;
      } else r.flow = 0;
    }
    const powered = supply >= demand && supply > 0;
    for (const [k, r] of recs) {
      const ri = info(r.t);
      const c = live.get(k);
      if (!c) continue;
      const wasPowered = r.powered;
      r.powered = ri.role === "generator" ? !!r.running : ri.role === "battery" ? (r.charge ?? 0) > 0 : powered && demandOf(r) > 0;
      if (ri.role === "reactor") r.powered = powered;
      r.net = { supply, demand, members: members.length };
      if (ri.role === "generator") setActive(c, !!r.running);
      else if (ri.role === "battery") setActive(c, (r.charge ?? 0) > 0);
      else if (ri.role === "computer" || ri.role === "server") {
        const on = r.powered && r.on !== false && !r.shutdown;
        if (on && !wasPowered) sound(c.dim, c.pos, "radiousti.pc_boot", 0.6);
        setActive(c, on);
      }
      if (ri.role === "generator" && r.running && cycleNo % 3 === 0) sound(c.dim, c.pos, "radiousti.generator_hum", 0.5);
      Machines.save(k);
    }
  }
  // isolated consumers that are not in any network
  for (const [key, ctx] of live) {
    if (visited.has(key)) continue;
    const rec = Machines.get(key);
    const ri = ctx.info;
    if (!ri) continue;
    if (ri.role === "computer" || ri.role === "server" || ri.role === "station") {
      if (rec.powered) {
        rec.powered = false;
        Machines.save(key);
      }
      rec.net = { supply: 0, demand: demandOf(rec), members: 1 };
      setActive(ctx, false);
    }
  }
}

export function startNetworkLoop() {
  system.runInterval(() => {
    try {
      runCycle();
    } catch (e) {
      console.warn(`[RadioÚstí] network cycle: ${e}\n${e?.stack ?? ""}`);
    }
  }, CYCLE_TICKS);
}

/** Water pump status: adjacent to a water source block. */
onCycle("beforePower", (liveMap) => {
  for (const [key, ctx] of liveMap) {
    const rec = Machines.get(key);
    if (rec.t !== `${NS}:water_pump`) continue;
    let ok = false;
    for (const d of DIRS6) {
      const b = blockAt(ctx.dim, add(ctx.pos, d));
      if (b && (b.typeId === "minecraft:water" || b.typeId === "minecraft:flowing_water")) ok = true;
    }
    if (rec.ok !== ok) {
      rec.ok = ok;
      Machines.save(key);
    }
  }
});

export function machinesNear(dimId, p, r) {
  const out = [];
  for (const [k, rec] of Machines.all()) {
    const q = parseKey(k);
    if (q.dim !== dimId) continue;
    if (dist2(p, q) <= r * r) out.push([k, rec, q]);
  }
  return out;
}

export { BlockPermutation, world };
