// Fictional RadioÚstí reactor: a game mechanic, not a real-world design.
// Structure: Reactor Core in the centre of a 3x3x3 shell made of Reactor Casing / Viewing Glass /
// ports / control panel. Needs >=1 coolant port, power port, waste port and control panel.
import { BlockPermutation } from "@minecraft/server";
import { NS, BLOCKS, blockAt, parseKey, posKey, dimOf, info, sound, dist2 } from "../lib/util.js";
import { Machines, Logs, Config } from "../lib/store.js";
import { onCycle, scanNetwork, waterSource, setActive, machinesNear } from "./network.js";
import { contaminateArea } from "./radiation.js";

export const SHELL = new Set([
  `${NS}:reactor_casing`, `${NS}:reactor_glass`, `${NS}:reactor_port_coolant`, `${NS}:reactor_port_power`,
  `${NS}:reactor_port_waste`, `${NS}:reactor_control_panel`,
]);
export const MAX_FUEL = 4;
export const ROD_CYCLES = 150; // 150 x 2 s = 5 minutes per fuel rod

export const STATUS_CS = {
  OFF: "Vypnuto", RUNNING: "V provozu", WARNING: "VAROVÁNÍ", CRITICAL: "KRITICKÝ STAV", SCRAM: "Nouzově odstaveno (SCRAM)",
  MELTDOWN: "TAVENÍ JÁDRA", NO_FUEL: "Bez paliva", INVALID: "Neúplná stavba",
};

export function checkStructure(dim, core) {
  const counts = { casing: 0, glass: 0, coolant: 0, power: 0, waste: 0, panel: 0 };
  const problems = [];
  const ports = { coolant: [], power: [], waste: [] };
  let unloaded = false;
  for (let dx = -1; dx <= 1; dx++)
    for (let dy = -1; dy <= 1; dy++)
      for (let dz = -1; dz <= 1; dz++) {
        if (!dx && !dy && !dz) continue;
        const p = { x: core.x + dx, y: core.y + dy, z: core.z + dz };
        const b = blockAt(dim, p);
        if (!b) {
          unloaded = true;
          continue;
        }
        if (!SHELL.has(b.typeId)) {
          if (problems.length < 6) problems.push(`Chybí plášť na ${p.x} ${p.y} ${p.z} (je tam ${b.typeId.replace("minecraft:", "")})`);
          continue;
        }
        const k = b.typeId.replace(`${NS}:`, "");
        if (k === "reactor_casing") counts.casing++;
        else if (k === "reactor_glass") counts.glass++;
        else if (k === "reactor_port_coolant") { counts.coolant++; ports.coolant.push(p); }
        else if (k === "reactor_port_power") { counts.power++; ports.power.push(p); }
        else if (k === "reactor_port_waste") { counts.waste++; ports.waste.push(p); }
        else if (k === "reactor_control_panel") counts.panel++;
      }
  if (!counts.coolant) problems.push("Chybí chladicí port (Reactor Coolant Port).");
  if (!counts.power) problems.push("Chybí energetický port (Reactor Power Port).");
  if (!counts.waste) problems.push("Chybí odpadní port (Reactor Waste Port).");
  if (!counts.panel) problems.push("Chybí řídicí panel (Reactor Control Panel).");
  return { ok: problems.length === 0 && !unloaded, unloaded, problems, counts, ports };
}

export function coolantStatus(dim, ports) {
  let units = 0, source = false, closed = 0;
  for (const p of ports) {
    const net = scanNetwork(dim, [p], "water");
    closed += net.closedValves;
    if (waterSource(net)) source = true;
    for (const mk of net.machines) if (Machines.get(mk)?.t === `${NS}:reactor_cooling_unit`) units++;
  }
  return { ok: units > 0 && source, units, source, closedValves: closed };
}

function wasteContainers(dim, ports) {
  const out = [];
  for (const p of ports) {
    const net = scanNetwork(dim, [p], "radioactive");
    for (const mk of net.machines) {
      const m = Machines.get(mk);
      if (m?.t === `${NS}:radioactive_waste_container`) out.push(mk);
    }
  }
  return out;
}

export function reactorReport(key) {
  const rec = Machines.get(key);
  if (!rec) return undefined;
  const p = parseKey(key);
  const dim = dimOf(p.dim);
  const s = checkStructure(dim, p);
  const cool = coolantStatus(dim, s.ports.coolant);
  const cont = wasteContainers(dim, s.ports.waste);
  return { rec, pos: p, dim, structure: s, coolant: cool, containers: cont };
}

export function startReactor(key, who = "obsluha") {
  const r = reactorReport(key);
  if (!r) return "Reaktor nenalezen.";
  const { rec } = r;
  if (rec.status === "MELTDOWN") return "Jádro je zničené.";
  if (!r.structure.ok) return "Stavba reaktoru není kompletní: " + (r.structure.problems[0] ?? "nenačtené chunky");
  if ((rec.fuel ?? 0) <= 0 && (rec.burn ?? 0) <= 0) return "Chybí palivo: vložte Uranovou palivovou tyč do řídicího panelu.";
  if (!r.coolant.ok) return r.coolant.units ? "Chladicí okruh nemá zdroj vody (vodní čerpadlo u vody nebo potrubí do vody)." :
    "Chladicí okruh nemá chladicí jednotku nebo je zavřený ventil.";
  if ((rec.heat ?? 0) >= 70) return "Jádro je příliš horké pro start (nad 70 %).";
  rec.running = true;
  rec.status = "RUNNING";
  Machines.save(key);
  sound(r.dim, r.pos, "radiousti.reactor_start", 1);
  Logs.push("alarms", `Reaktor ${r.pos.x} ${r.pos.y} ${r.pos.z} spuštěn (${who}).`);
  return "OK";
}

export function scram(key, reason = "ručně") {
  const rec = Machines.get(key);
  if (!rec || rec.status === "MELTDOWN") return;
  const p = parseKey(key);
  const was = rec.running;
  rec.running = false;
  rec.status = "SCRAM";
  Machines.save(key);
  const dim = dimOf(p.dim);
  sound(dim, p, "radiousti.reactor_scram", 1);
  Logs.push("alarms", `SCRAM reaktoru ${p.x} ${p.y} ${p.z}: ${reason}${was ? "" : " (reaktor již stál)"}.`);
}

export function resetReactor(key) {
  const rec = Machines.get(key);
  if (!rec) return "Reaktor nenalezen.";
  if (rec.status === "MELTDOWN") return "Jádro je zničené.";
  if (rec.running) return "Reaktor běží – nejdřív ho odstavte.";
  if ((rec.heat ?? 0) > 30) return "Počkejte, až teplota klesne pod 30 %.";
  rec.status = "OFF";
  Machines.save(key);
  return "OK";
}

export function insertFuel(key) {
  const rec = Machines.get(key);
  if (!rec) return "Reaktor nenalezen.";
  if ((rec.fuel ?? 0) >= MAX_FUEL) return `Zásobník paliva je plný (${MAX_FUEL} tyče).`;
  rec.fuel = (rec.fuel ?? 0) + 1;
  Machines.save(key);
  return "OK";
}

export function reactorsNear(dimId, p, r) {
  return machinesNear(dimId, p, r).filter(([, rec]) => rec.t === `${NS}:reactor_core`);
}

function meltdown(key, ctx) {
  const rec = Machines.get(key);
  rec.running = false;
  rec.status = "MELTDOWN";
  Machines.save(key);
  Logs.push("alarms", `!!! TAVENÍ JÁDRA reaktoru ${ctx.pos.x} ${ctx.pos.y} ${ctx.pos.z} – kontaminace okolí.`);
  Logs.push("contamination", `Tavení jádra na ${ctx.pos.x} ${ctx.pos.y} ${ctx.pos.z}: zamořen okruh 7 bloků.`);
  try {
    ctx.block.setPermutation(BlockPermutation.resolve(`${NS}:damaged_reactor_core`));
  } catch (e) {
    console.warn(`[RadioÚstí] meltdown core swap: ${e}`);
  }
  contaminateArea(ctx.dim, ctx.pos, 7, 160, 10);
  if (Config.get().meltdownExplosion) {
    try {
      ctx.dim.createExplosion({ x: ctx.pos.x + 0.5, y: ctx.pos.y + 2, z: ctx.pos.z + 0.5 }, 3, { breaksBlocks: false, causesFire: false });
    } catch {
      /* explosions may be disabled */
    }
  }
  Machines.delete(key);
}

onCycle("beforePower", (live) => {
  for (const [key, ctx] of live) {
    const rec = Machines.get(key);
    if (rec.t !== `${NS}:reactor_core`) continue;
    const s = checkStructure(ctx.dim, ctx.pos);
    if (s.unloaded) continue;
    const cool = coolantStatus(ctx.dim, s.ports.coolant);
    rec.coolantOk = cool.ok;
    rec.coolingUnits = cool.units;
    rec.structureOk = s.ok;
    if (!s.ok && rec.running) scram(key, "narušená stavba");
    if (rec.running) {
      if ((rec.burn ?? 0) <= 0) {
        if ((rec.fuel ?? 0) > 0) {
          rec.fuel--;
          rec.burn = ROD_CYCLES;
        } else {
          rec.running = false;
          rec.status = "NO_FUEL";
          Logs.push("alarms", `Reaktor ${ctx.pos.x} ${ctx.pos.y} ${ctx.pos.z} se zastavil: došlo palivo.`);
        }
      }
    }
    if (rec.running) {
      rec.burn--;
      const target = cool.ok ? Math.max(30, 55 - 10 * (cool.units - 1)) : 200;
      const delta = Math.max(-3, Math.min(4, target - rec.heat));
      rec.heat = Math.min(100, rec.heat + delta);
      rec.wasteTick = (rec.wasteTick ?? 0) + 1;
      if (rec.wasteTick >= 10) {
        rec.wasteTick = 0;
        rec.waste = (rec.waste ?? 0) + 1;
      }
    } else {
      rec.heat = Math.max(0, rec.heat - (cool.ok ? 4 : 1));
    }
    // move internal waste to containers
    if ((rec.waste ?? 0) > 0) {
      for (const ck of wasteContainers(ctx.dim, s.ports.waste)) {
        const c = Machines.get(ck);
        const cap = info(c.t)?.capacity ?? 200;
        while (rec.waste > 0 && (c.waste ?? 0) < cap) {
          c.waste = (c.waste ?? 0) + 1;
          rec.waste--;
        }
        Machines.save(ck);
      }
    }
    rec.leak = (rec.waste ?? 0) >= 10;
    if (rec.leak && Math.random() < 0.5) contaminateArea(ctx.dim, ctx.pos, 5, 2, 0);
    // status
    if (rec.running) {
      if (rec.heat >= 100) {
        meltdown(key, ctx);
        continue;
      }
      if (rec.heat >= 95 && rec.protect !== false) {
        scram(key, "automatická ochrana – teplota 95 %");
      } else if (rec.heat >= 90) rec.status = "CRITICAL";
      else if (rec.heat >= 75 || rec.leak) rec.status = "WARNING";
      else rec.status = "RUNNING";
    } else if (rec.status === "RUNNING" || rec.status === "WARNING" || rec.status === "CRITICAL") {
      rec.status = "OFF";
    }
    if (!s.ok && rec.status !== "SCRAM" && rec.status !== "MELTDOWN") rec.status = "INVALID";
    else if (s.ok && rec.status === "INVALID") rec.status = "OFF";
    const prev = rec.lastStatus;
    if (prev !== rec.status && (rec.status === "WARNING" || rec.status === "CRITICAL")) {
      Logs.push("alarms", `Reaktor ${ctx.pos.x} ${ctx.pos.y} ${ctx.pos.z}: ${STATUS_CS[rec.status]} (teplota ${rec.heat} %${rec.leak ? ", únik odpadu" : ""}).`);
    }
    rec.lastStatus = rec.status;
    setActive(ctx, !!rec.running);
    Machines.save(key);
  }
});

export function isAlertStatus(s) {
  return s === "WARNING" || s === "CRITICAL" || s === "MELTDOWN";
}

export { BLOCKS, posKey, dist2 };
