// Persistent state stored in world dynamic properties.
//   ru:m:<dim>|x|y|z  -> JSON machine record { t: typeId, ...state }
//   ru:log:<channel>  -> JSON array (capped) for alarm history, lab records, contamination reports
//   ru:cfg            -> JSON config
//   ru:dose:<player>  -> stored on the player entity instead (see radiation.js)
import { world } from "@minecraft/server";

const M = "ru:m:";
const cache = new Map(); // key -> record (write-through)
let loaded = false;

function loadAll() {
  if (loaded) return;
  loaded = true;
  for (const id of world.getDynamicPropertyIds()) {
    if (!id.startsWith(M)) continue;
    try {
      cache.set(id.slice(M.length), JSON.parse(String(world.getDynamicProperty(id))));
    } catch {
      world.setDynamicProperty(id, undefined);
    }
  }
}

export const Machines = {
  all() {
    loadAll();
    return cache;
  },
  get(key) {
    loadAll();
    return cache.get(key);
  },
  set(key, rec) {
    loadAll();
    cache.set(key, rec);
    world.setDynamicProperty(M + key, JSON.stringify(rec));
  },
  /** Persist a record that was mutated in place. */
  save(key) {
    const rec = cache.get(key);
    if (rec) world.setDynamicProperty(M + key, JSON.stringify(rec));
  },
  delete(key) {
    loadAll();
    cache.delete(key);
    world.setDynamicProperty(M + key, undefined);
  },
};

const LOG_CAP = 40;

export const Logs = {
  get(channel) {
    try {
      return JSON.parse(String(world.getDynamicProperty("ru:log:" + channel) ?? "[]"));
    } catch {
      return [];
    }
  },
  push(channel, text) {
    const arr = Logs.get(channel);
    const day = Math.floor(world.getAbsoluteTime() / 24000);
    const t = world.getTimeOfDay();
    const hh = String(Math.floor(((t / 1000) + 6) % 24)).padStart(2, "0");
    const mm = String(Math.floor(((t % 1000) / 1000) * 60)).padStart(2, "0");
    arr.unshift(`[Den ${day} ${hh}:${mm}] ${text}`);
    while (arr.length > LOG_CAP) arr.pop();
    world.setDynamicProperty("ru:log:" + channel, JSON.stringify(arr));
  },
  clear(channel) {
    world.setDynamicProperty("ru:log:" + channel, "[]");
  },
};

const DEFAULT_CFG = { radiation: true, radiationMultiplier: 1, wasteSpread: true, meltdownExplosion: true, zedDrops: true,
  environment: true, rainRadiation: true };

export const Config = {
  get() {
    try {
      return { ...DEFAULT_CFG, ...JSON.parse(String(world.getDynamicProperty("ru:cfg") ?? "{}")) };
    } catch {
      return { ...DEFAULT_CFG };
    }
  },
  set(patch) {
    const c = { ...Config.get(), ...patch };
    world.setDynamicProperty("ru:cfg", JSON.stringify(c));
    return c;
  },
};
