// Lights, alarms, radiation indicators and emergency controls.
import { system } from "@minecraft/server";
import { NS, info, stateOf, setState, sound, parseKey, dist2 } from "../lib/util.js";
import { Machines, Logs } from "../lib/store.js";
import { onCycle, getCycle } from "./network.js";
import { isAlertStatus, scram, reactorsNear } from "./reactor.js";
import { radiationAt, lastRateOf } from "./radiation.js";
import { world } from "@minecraft/server";

const LIT = `${NS}:lit`;

export function toggleLight(block, key) {
  const lit = !stateOf(block, LIT, false);
  setState(block, LIT, lit);
  if (key) {
    const rec = Machines.get(key);
    if (rec) {
      rec.manual = lit;
      Machines.save(key);
    }
  }
  sound(block.dimension, block.location, "radiousti.light_switch", 0.8);
  return lit;
}

function reactorAlertNear(dimId, p, r) {
  return reactorsNear(dimId, p, r).some(([, rec]) => isAlertStatus(rec.status));
}

function powerLossNear(dimId, p, r) {
  for (const [k, rec] of Machines.all()) {
    const q = parseKey(k);
    if (q.dim !== dimId || dist2(p, q) > r * r) continue;
    const i = info(rec.t);
    if (i?.demand > 0 && rec.on !== false && rec.powered === false && rec.net) return true;
  }
  return false;
}

function playerRadiationNear(dimId, p, r) {
  for (const pl of world.getAllPlayers()) {
    if (pl.dimension.id !== dimId) continue;
    if (dist2(pl.location, p) <= r * r && lastRateOf(pl) > 0.3) return true;
  }
  return false;
}

export function alarmCondition(rec, ctx) {
  const i = info(rec.t);
  const now = system.currentTick;
  if ((rec.test ?? 0) > 0) return { on: true, why: "test" };
  if ((rec.silencedUntil ?? 0) > now) return { on: false, why: "ztlumeno" };
  if (reactorAlertNear(ctx.dim.id, ctx.pos, 32)) return { on: true, why: "reaktor" };
  if (i.trigger === "radiation" || i.trigger === "any") {
    if (radiationAt(ctx.dim, ctx.pos, 5) > 1.5) return { on: true, why: "radiace v okolí" };
    if (playerRadiationNear(ctx.dim.id, ctx.pos, 12)) return { on: true, why: "ozářená osoba" };
  }
  return { on: false, why: "klid" };
}

onCycle("afterPower", (live) => {
  for (const [key, ctx] of live) {
    const rec = Machines.get(key);
    const i = ctx.info;
    if (!i) continue;
    if (i.kind === "light" && i.auto) {
      const cond = i.auto === "reactor_warning" ? reactorAlertNear(ctx.dim.id, ctx.pos, 32) : powerLossNear(ctx.dim.id, ctx.pos, 16);
      rec.autoActive = cond;
      setState(ctx.block, LIT, !!rec.manual || cond);
    } else if (i.kind === "alarm") {
      const c = alarmCondition(rec, ctx);
      if (rec.test > 0) rec.test--;
      const was = stateOf(ctx.block, LIT, false);
      setState(ctx.block, LIT, c.on);
      if (c.on && !was) Logs.push("alarms", `${i.cs} ${ctx.pos.x} ${ctx.pos.y} ${ctx.pos.z} spuštěn: ${c.why}.`);
      rec.why = c.why;
      if (c.on) sound(ctx.dim, ctx.pos, rec.t === `${NS}:alarm` ? "radiousti.alarm" : "radiousti.radiation_alarm", 1);
      Machines.save(key);
    } else if (i.kind === "indicator") {
      let lvl = radiationAt(ctx.dim, ctx.pos, 6);
      const level = lvl > 4 ? 3 : lvl > 1.5 ? 2 : lvl > 0.2 ? 1 : 0;
      rec.level = level;
      rec.value = Number(lvl.toFixed(2));
      setState(ctx.block, `${NS}:level`, level);
      if (getCycle() % 5 === 0) Machines.save(key);
    }
  }
});

export function interactAlarm(key, block) {
  const rec = Machines.get(key);
  if (!rec) return "";
  if (stateOf(block, LIT, false)) {
    rec.silencedUntil = system.currentTick + 20 * 60;
    rec.test = 0;
    setState(block, LIT, false);
    Machines.save(key);
    return "Alarm ztlumen na 60 sekund.";
  }
  rec.test = 2;
  Machines.save(key);
  return "Test alarmu spuštěn (4 sekundy).";
}

export function pressScram(dim, pos) {
  const list = reactorsNear(dim.id, pos, 24);
  for (const [k] of list) scram(k, "tlačítko nouzového odstavení");
  sound(dim, pos, "radiousti.reactor_scram", 1);
  return list.length;
}
