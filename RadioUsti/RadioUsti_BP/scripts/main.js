// RadioÚstí | Zeds World add-on by Jackhack2021 - script entry point.
// Target: Minecraft Bedrock 1.26.50, stable @minecraft/server 2.0.0 + @minecraft/server-ui 2.0.0.
// Runtime behaviour has only been statically validated (type-checked against the official
// typings); in-game testing is tracked in FEATURES.md.
import { world, system, BlockPermutation, EquipmentSlot } from "@minecraft/server";
import { NS, BLOCKS, ITEMS, info, stateOf, setState, isCreative, dropItem, sound, heldItem, consumeHeld, giveItem, later, safe, posKey } from "./lib/util.js";
import { Machines, Config, Logs } from "./lib/store.js";
import { updateAround } from "./systems/connections.js";
import { buildMultiblock, breakMultiblock, buildDoor, breakDoor, toggleDoor, originOf } from "./systems/structures.js";
import { startNetworkLoop, ensureMachine, findCoreNear } from "./systems/network.js";
import "./systems/reactor.js";
import { startSmog } from "./systems/environment.js";
import { radiationTick, wasteSpreadTick, decontaminate, getDose, setDose } from "./systems/radiation.js";
import { toggleLight, interactAlarm, pressScram } from "./systems/devices.js";
import { openStation } from "./systems/lab.js";
import { liquidTick, pourBucket, fillBucket, isLiquid } from "./systems/liquids.js";
import { showInspection } from "./ui/analyzer.js";
import { openComputer } from "./ui/pc.js";
import { openMachine, openReactorPanel, openServer, openHandbook, openRegistry, readDocument } from "./ui/panels.js";

const ANALYZER = `${NS}:system_analyzer`;
const DECON = `${NS}:decontamination_kit`;
const PICK = `${NS}:realistic_pickaxe`;
const ZOMBIES = new Set(["minecraft:zombie", "minecraft:husk", "minecraft:drowned", "minecraft:zombie_villager", "minecraft:zombie_villager_v2"]);

function needsRecord(i) {
  return i && (i.kind === "machine" || i.kind === "alarm" || i.kind === "indicator" || (i.kind === "light" && i.auto));
}

// ------------------------------------------------------------------ custom block components
system.beforeEvents.startup.subscribe((ev) => {
  const reg = (id, def) => ev.blockComponentRegistry.registerCustomComponent(`${NS}:${id}`, def);
  const ui = (fn) => safe("ui", (e) => {
    if (!e.player) return;
    const p = e.player, b = e.block;
    system.run(() => fn(p, b).catch?.((err) => console.warn(`[RadioÚstí] ui: ${err}`)));
  });

  reg("valve", {
    onPlayerInteract: safe("valve", (e) => {
      const open = !stateOf(e.block, `${NS}:open`, true);
      setState(e.block, `${NS}:open`, open);
      sound(e.dimension, e.block.location, "radiousti.valve", 1, open ? 1.1 : 0.8);
      e.player?.onScreenDisplay.setActionBar(open ? "§aVentil OTEVŘEN" : "§cVentil ZAVŘEN");
      Logs.push("alarms", `Ventil ${info(e.block.typeId).cs} ${e.block.location.x} ${e.block.location.y} ${e.block.location.z} ${open ? "otevřen" : "zavřen"}${e.player ? " (" + e.player.name + ")" : ""}.`);
    }),
  });
  reg("machine", { onPlayerInteract: ui(async (p, b) => { const [k] = ensureMachine(b); if (k) await openMachine(p, b, k); }) });
  reg("computer", { onPlayerInteract: ui(async (p, b) => { const [k] = ensureMachine(b); if (k) await openComputer(p, b, k); }) });
  reg("server", { onPlayerInteract: ui(async (p, b) => { const [k] = ensureMachine(b); if (k) await openServer(p, b, k); }) });
  reg("lab_station", { onPlayerInteract: ui(async (p, b) => { const [k] = ensureMachine(b); if (k) await openStation(p, b, k, info(b.typeId).station); }) });
  reg("reactor_panel", {
    onPlayerInteract: ui(async (p, b) => {
      const core = findCoreNear(b.dimension, b.location);
      if (!core) return p.sendMessage("§cŘídicí panel musí být součástí pláště kolem jádra reaktoru.");
      const cb = b.dimension.getBlock(core);
      if (cb) ensureMachine(cb);
      await openReactorPanel(p, b, posKey(b.dimension.id, core));
    }),
  });
  reg("scram_button", {
    onPlayerInteract: safe("scram", (e) => {
      const n = pressScram(e.dimension, e.block.location);
      e.player?.sendMessage(n ? `§c§lSCRAM§r – odstaveno reaktorů: ${n}` : "§7V okruhu 24 bloků není žádný reaktor.");
    }),
  });
  reg("indicator", {
    onPlayerInteract: safe("indicator", (e) => {
      const [, rec] = ensureMachine(e.block);
      e.player?.onScreenDisplay.setActionBar(`§eIndikátor radiace: úroveň ${rec?.level ?? 0}/3 (${rec?.value ?? 0})`);
    }),
  });
  reg("light_switch", {
    onPlayerInteract: safe("light", (e) => {
      const i = info(e.block.typeId);
      const key = i.auto ? ensureMachine(e.block)[0] : undefined;
      toggleLight(e.block, key);
    }),
  });
  reg("alarm", {
    onPlayerInteract: safe("alarm", (e) => {
      const [k] = ensureMachine(e.block);
      const m = k ? interactAlarm(k, e.block) : "";
      if (m) e.player?.onScreenDisplay.setActionBar(`§e${m}`);
    }),
  });
  reg("door", { onPlayerInteract: safe("door", (e) => toggleDoor(e.block)) });
  reg("bed", {
    onPlayerInteract: safe("bed", (e) => {
      if (!e.player) return;
      const o = originOf(e.block);
      e.player.setSpawnPoint({ dimension: e.dimension, x: o.x, y: o.y + 1, z: o.z });
      e.player.sendMessage("§aBod oživení nastaven u nemocničního lůžka.");
    }),
  });
  reg("rotate_on_use", {
    onPlayerInteract: safe("rotate", (e) => {
      const order = ["north", "east", "south", "west"];
      const cur = stateOf(e.block, "minecraft:cardinal_direction", "north");
      setState(e.block, "minecraft:cardinal_direction", order[(order.indexOf(cur) + 1) % 4]);
      sound(e.dimension, e.block.location, "radiousti.pc_click", 0.5, 0.5);
    }),
  });
  reg("readable", { onPlayerInteract: ui(async (p, b) => readDocument(p, info(b.typeId).doc)) });
  reg("papers", {
    onPlace: safe("papers", (e) => setState(e.block, `${NS}:variant`, Math.floor(Math.random() * 4))),
    onPlayerInteract: ui(async (p) => readDocument(p, "scattered_papers")),
  });
  reg("clock", {
    onPlayerInteract: safe("clock", (e) => {
      const t = world.getTimeOfDay();
      const hh = String(Math.floor(((t / 1000) + 6) % 24)).padStart(2, "0");
      const mm = String(Math.floor(((t % 1000) / 1000) * 60)).padStart(2, "0");
      e.player?.onScreenDisplay.setActionBar(`§fHodiny ukazují §e${hh}:${mm}§f, den ${Math.floor(world.getAbsoluteTime() / 24000)}`);
    }),
  });
  reg("jar", {
    onPlayerInteract: safe("jar", (e) => {
      const p = e.player;
      if (!p) return;
      const fill = stateOf(e.block, `${NS}:fill`, 0);
      const it = heldItem(p);
      const FILL = { [`${NS}:blood_bottle`]: 1, [`${NS}:infected_flesh`]: 2, [`${NS}:soul_essence`]: 3 };
      if (fill === 0 && it && FILL[it.typeId]) {
        consumeHeld(p, 1);
        if (it.typeId === `${NS}:blood_bottle`) giveItem(p, "minecraft:glass_bottle", 1);
        setState(e.block, `${NS}:fill`, FILL[it.typeId]);
        return;
      }
      if (fill !== 0 && it?.typeId === "minecraft:glass_bottle" && fill === 1) {
        consumeHeld(p, 1);
        giveItem(p, `${NS}:blood_bottle`, 1);
        setState(e.block, `${NS}:fill`, 0);
        return;
      }
      p.onScreenDisplay.setActionBar(`Preparátová nádoba: ${["prázdná – vložte láhev krve, maso nebo esenci duše", "krev (vyberte skleněnou lahví)", "maso", "duše"][fill]}`);
    }),
  });
  const particles = (id, dy, cond) => safe("particles", (e) => {
    if (cond && !cond(e.block)) return;
    const l = e.block.location;
    try {
      e.dimension.spawnParticle(id, { x: l.x + 0.5, y: l.y + dy, z: l.z + 0.5 });
    } catch {
      /* particle id unavailable */
    }
  });
  reg("shower", { onTick: particles("minecraft:water_splash_particle", 0.6, (b) => stateOf(b, `${NS}:lit`, false)) });
  reg("steam_vent", { onTick: particles("minecraft:campfire_smoke_particle", 0.7) });
  reg("brazier", { onTick: particles("minecraft:basic_flame_particle", 0.85) });
  reg("liquid", { onTick: safe("liquid", (e) => liquidTick(e.block)) });
  reg("waste_spread", { onTick: safe("waste", (e) => wasteSpreadTick(e.block)) });
  const hurt = (dmg, slow) => safe("hazard", (e) => {
    const ent = e.entity;
    if (!ent) return;
    try {
      ent.applyDamage(dmg);
      if (slow) ent.addEffect("slowness", 40, { amplifier: 2, showParticles: false });
    } catch {
      /* not damageable */
    }
  });
  reg("barbed_wire", { onStepOn: hurt(1, true) });
  reg("spikes", { onStepOn: hurt(2, false) });
});

// ------------------------------------------------------------------ analyzer & decontamination kit
world.beforeEvents.playerInteractWithBlock.subscribe((ev) => {
  const id = ev.itemStack?.typeId;
  if (id === ANALYZER) {
    ev.cancel = true;
    if (!ev.isFirstEvent) return;
    const p = ev.player, b = ev.block;
    system.run(() => showInspection(p, b).catch((e) => console.warn(`[RadioÚstí] analyzer: ${e}`)));
  } else if (ITEMS[id]?.kind === "liquid_bucket") {
    ev.cancel = true;
    if (!ev.isFirstEvent) return;
    const p = ev.player, b = ev.block, face = ev.blockFace;
    system.run(() => pourBucket(p, b, face, id));
  } else if (id === "minecraft:bucket" && isLiquid(ev.block.typeId)) {
    ev.cancel = true;
    if (!ev.isFirstEvent) return;
    const p = ev.player, b = ev.block;
    system.run(() => fillBucket(p, b));
  } else if (id === DECON && BLOCKS[ev.block.typeId]?.clean) {
    ev.cancel = true;
    if (!ev.isFirstEvent) return;
    const p = ev.player, b = ev.block;
    system.run(() => {
      if (!decontaminate(b)) return;
      sound(b.dimension, b.location, "radiousti.valve", 0.6, 1.8);
      damageHeld(p, 1);
    });
  }
});

function damageHeld(player, n) {
  if (isCreative(player)) return;
  const c = player.getComponent("minecraft:inventory")?.container;
  const it = c?.getItem(player.selectedSlotIndex);
  const d = it?.getComponent("minecraft:durability");
  if (!it || !d) return;
  if (d.damage + n >= d.maxDurability) {
    c.setItem(player.selectedSlotIndex, undefined);
    sound(player.dimension, player.location, "random.break", 1);
  } else {
    d.damage += n;
    c.setItem(player.selectedSlotIndex, it);
  }
}

// ------------------------------------------------------------------ placement / breaking
world.afterEvents.playerPlaceBlock.subscribe(safe("place", (ev) => {
  const b = ev.block;
  const i = info(b.typeId);
  if (i?.multiblock && stateOf(b, `${NS}:part`, 0) === 0) {
    if (!buildMultiblock(ev.player, b)) return;
  }
  if (i?.kind === "door" && !stateOf(b, `${NS}:upper`, false)) {
    if (!buildDoor(ev.player, b)) return;
  }
  if (needsRecord(i)) {
    const fresh = b.dimension.getBlock(b.location);
    if (fresh) ensureMachine(fresh);
  }
  updateAround(b.dimension, b.location);
  if (i?.multiblock) later(() => updateAround(b.dimension, b.location), 2);
}));

world.afterEvents.playerBreakBlock.subscribe(safe("break", (ev) => {
  const perm = ev.brokenBlockPermutation;
  const typeId = perm.type.id;
  const i = info(typeId);
  const dim = ev.dimension ?? ev.block.dimension;
  const loc = ev.block.location;
  if (i?.multiblock) {
    const origin = breakMultiblock(dim, loc, perm, ev.player);
    Machines.delete(posKey(dim.id, origin));
  } else if (i?.kind === "door") {
    breakDoor(dim, loc, perm, ev.player);
  } else if (needsRecord(i)) {
    Machines.delete(posKey(dim.id, loc));
  }
  updateAround(dim, loc);
  // Realistic Pickaxe: manual durability + careful uranium extraction
  if (ev.itemStackBeforeBreak?.typeId === PICK) {
    damageHeld(ev.player, 1);
    if ((typeId === `${NS}:uranium_ore` || typeId === `${NS}:deepslate_uranium_ore`) && Math.random() < 0.5 && !isCreative(ev.player)) {
      dropItem(dim, loc, `${NS}:raw_uranium`, 1);
    }
  }
}));

// ------------------------------------------------------------------ items
world.afterEvents.itemUse.subscribe(safe("itemUse", (ev) => {
  const id = ev.itemStack.typeId;
  const p = ev.source;
  if (id === `${NS}:handbook`) system.run(() => openHandbook(p).catch(() => {}));
  else if (id === `${NS}:experiment_registry`) system.run(() => openRegistry(p).catch(() => {}));
  else if (ITEMS[id]?.kind === "document") system.run(() => readDocument(p, id).catch(() => {}));
  else if (id === ANALYZER) p.onScreenDisplay.setActionBar(`§eAnalyzátor: klepněte na blok. Vaše dávka radiace: ${getDose(p).toFixed(0)}/150`);
}));

world.afterEvents.itemCompleteUse.subscribe(safe("consume", (ev) => {
  const id = ev.itemStack.typeId;
  const p = ev.source;
  if (id === `${NS}:anti_radiation_pills`) {
    setDose(p, getDose(p) - 40);
    p.onScreenDisplay.setActionBar(`§aAntiradiační tablety: dávka ${getDose(p).toFixed(0)}`);
  } else if (id === `${NS}:biogenic_serum`) {
    p.addEffect("regeneration", 300, { amplifier: 1 });
    p.addEffect("nausea", 100, { amplifier: 0 });
    p.onScreenDisplay.setActionBar("§dBiogenní sérum B-9: tkáně se spojují…");
  } else if (id === `${NS}:zed_serum`) {
    setDose(p, getDose(p) - 10);
    p.addEffect("regeneration", 200, { amplifier: 1 });
    p.removeEffect("poison");
    p.removeEffect("wither");
  }
}));

world.afterEvents.entityDie.subscribe(safe("zedDrops", (ev) => {
  const e = ev.deadEntity;
  if (!ZOMBIES.has(e.typeId) || !Config.get().zedDrops) return;
  if (ev.damageSource?.damagingEntity?.typeId !== "minecraft:player") return;
  const loc = { x: Math.floor(e.location.x), y: Math.floor(e.location.y), z: Math.floor(e.location.z) };
  if (Math.random() < 0.35) dropItem(e.dimension, loc, `${NS}:infected_flesh`, 1);
  if (Math.random() < 0.15) dropItem(e.dimension, loc, `${NS}:blood_bottle`, 1);
}));

// ------------------------------------------------------------------ config & status commands
system.afterEvents.scriptEventReceive.subscribe(safe("scriptevent", (ev) => {
  if (ev.id === `${NS}:config`) {
    const [k, v] = ev.message.trim().split(/\s+/);
    const on = v === "on" || v === "true";
    let c;
    if (k === "radiation") c = Config.set({ radiation: on });
    else if (k === "multiplier") c = Config.set({ radiationMultiplier: Math.max(0, Number(v) || 1) });
    else if (k === "wastespread") c = Config.set({ wasteSpread: on });
    else if (k === "explosion") c = Config.set({ meltdownExplosion: on });
    else if (k === "zeddrops") c = Config.set({ zedDrops: on });
    else if (k === "environment") c = Config.set({ environment: on });
    else if (k === "rainradiation") c = Config.set({ rainRadiation: on });
    else if (k === "smog") {
      startSmog(Number(v) || 3);
      c = Config.get();
    }
    else c = Config.get();
    world.sendMessage(`§e[RadioÚstí] Nastavení: ${JSON.stringify(c)}`);
  } else if (ev.id === `${NS}:status`) {
    world.sendMessage(`§e[RadioÚstí] Registrovaných strojů: ${Machines.all().size}`);
  }
}));

// ------------------------------------------------------------------ loops
startNetworkLoop();
system.runInterval(safe("radiation", () => radiationTick(world.getAllPlayers())), 40);

world.afterEvents.worldLoad.subscribe(() => {
  console.warn(`[RadioÚstí] Načteno: ${Object.keys(BLOCKS).length} bloků, ${Object.keys(ITEMS).length} předmětů, strojů ve světě ${Machines.all().size}.`);
});

export { BlockPermutation, EquipmentSlot };
