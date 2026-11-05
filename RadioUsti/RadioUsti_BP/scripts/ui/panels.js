// Machine panels, reactor control panel, server rack, handbook and document reader.
import { ActionFormData, MessageFormData } from "@minecraft/server-ui";
import { NS, info, heldItem, consumeHeld, giveItem, sound, isCreative } from "../lib/util.js";
import { Machines, Logs } from "../lib/store.js";
import { describeMachine, machineLabel } from "./describe.js";
import { startReactor, scram, resetReactor, insertFuel, STATUS_CS } from "../systems/reactor.js";
import { visibleMachines } from "./pc.js";
import { HANDBOOK } from "../data/handbook.js";
import { DOCS } from "../data/lore.js";

const FUEL = {
  [`${NS}:generator_standard`]: { "minecraft:coal": 40, "minecraft:charcoal": 40, "minecraft:coal_block": 360, [`${NS}:canister_industrial_oil`]: 60 },
  [`${NS}:generator_backup`]: { "minecraft:coal": 40, "minecraft:charcoal": 40, "minecraft:coal_block": 360 },
};
const MAX_FUEL_CYCLES = 1200;

/** Try to use the held item on a machine. Returns a message, or undefined when nothing applied. */
function useItemOnMachine(player, key, rec) {
  const it = heldItem(player);
  if (!it) return undefined;
  const i = info(rec.t) ?? {};
  const fuel = FUEL[rec.t]?.[it.typeId];
  if (fuel) {
    if ((rec.fuel ?? 0) + fuel > MAX_FUEL_CYCLES) return "§eZásobník paliva je plný.";
    consumeHeld(player, 1);
    if (it.typeId.endsWith("_oil")) giveItem(player, `${NS}:empty_canister`, 1);
    rec.fuel = (rec.fuel ?? 0) + fuel;
    Machines.save(key);
    return `§aPalivo doplněno: ${rec.fuel} cyklů (${rec.fuel * 2} s).`;
  }
  if (rec.t === `${NS}:lab_power_unit` && (it.typeId === "minecraft:redstone" || it.typeId === "minecraft:redstone_block")) {
    const add = it.typeId === "minecraft:redstone" ? 50 : 450;
    if ((rec.charge ?? 0) + add > i.capacity) return "§eBaterie je téměř plná.";
    consumeHeld(player, 1);
    rec.charge = (rec.charge ?? 0) + add;
    Machines.save(key);
    return `§aBaterie nabita na ${rec.charge}/${i.capacity}.`;
  }
  if (rec.t === `${NS}:gas_tank` && it.typeId === `${NS}:gas_canister`) {
    if ((rec.gas ?? 0) + 100 > i.capacity) return "§eNádrž je plná.";
    consumeHeld(player, 1);
    giveItem(player, `${NS}:empty_canister`, 1);
    rec.gas = (rec.gas ?? 0) + 100;
    Machines.save(key);
    return `§aPlyn doplněn: ${rec.gas}/${i.capacity}.`;
  }
  if (i.role === "tank" && i.family === "oil") {
    const want = `${NS}:canister_${i.oil}_oil`;
    if (it.typeId === want) {
      if ((rec.amount ?? 0) >= i.capacity) return "§eSud je plný.";
      consumeHeld(player, 1);
      giveItem(player, `${NS}:empty_canister`, 1);
      rec.amount = (rec.amount ?? 0) + 1;
      Machines.save(key);
      return `§aDo sudu přidán 1 kanystr (${rec.amount}/${i.capacity}).`;
    }
    if (it.typeId === `${NS}:empty_canister`) {
      if ((rec.amount ?? 0) <= 0) return "§eSud je prázdný.";
      consumeHeld(player, 1);
      giveItem(player, want, 1);
      rec.amount--;
      Machines.save(key);
      return `§aNatočen 1 kanystr (${rec.amount}/${i.capacity}).`;
    }
    if (it.typeId.startsWith(`${NS}:canister_`)) return "§cTento sud přijímá jen svůj typ oleje.";
  }
  return undefined;
}

export async function openMachine(player, block, key) {
  const rec = Machines.get(key);
  if (!rec) return;
  const used = useItemOnMachine(player, key, rec);
  if (used) {
    player.onScreenDisplay.setActionBar(used);
    sound(block.dimension, block.location, "radiousti.valve", 0.4, 1.6);
    return;
  }
  const i = info(rec.t) ?? {};
  if (i.role === "reactor") return openReactorPanel(player, block, key);
  const f = new ActionFormData().title(`§l${i.cs}`).body(describeMachine(key, rec).join("\n") + hintFor(rec));
  const acts = [];
  if (["generator", "battery", "computer", "server", "station"].includes(i.role)) {
    f.button(rec.on === false ? "§aZapnout" : "§cVypnout");
    acts.push(() => {
      rec.on = rec.on === false;
      Machines.save(key);
      if (i.role === "generator" && rec.on) sound(block.dimension, block.location, "radiousti.generator_start", 1);
    });
  }
  f.button("Zavřít");
  const r = await f.show(player);
  if (r.canceled || r.selection === undefined) return;
  acts[r.selection]?.();
}

function hintFor(rec) {
  switch (rec.t) {
    case `${NS}:generator_standard`: return "\n\n§7Palivo: klepněte s uhlím, dřevěným uhlím, uhelným blokem nebo kanystrem průmyslového oleje. Automaticky bere olej ze sudu přes průmyslové potrubí.§r";
    case `${NS}:generator_backup`: return "\n\n§7Palivo: uhlí. Startuje jen, když ostatní zdroje v síti nestačí.§r";
    case `${NS}:generator_industrial`: return "\n\n§7Připojte potrubí na roztavený materiál zakončené v lávě, nebo plynové potrubí s plynovou nádrží.§r";
    case `${NS}:generator_nuclear`: return "\n\n§7Propojte kabelem s energetickým portem běžícího reaktoru.§r";
    case `${NS}:lab_power_unit`: return "\n\n§7Nabíjí se přebytkem sítě nebo klepnutím s ruditem / blokem ruditu.§r";
    case `${NS}:gas_tank`: return "\n\n§7Doplňte klepnutím s plynovou bombou (+100).§r";
    default:
      if (info(rec.t)?.family === "oil") return "\n\n§7Klepněte s kanystrem správného oleje pro uložení, s prázdným kanystrem pro natočení.§r";
      return "";
  }
}

export async function openReactorPanel(player, block, key) {
  const rec = Machines.get(key);
  if (!rec) {
    player.sendMessage("§cŘídicí panel nesousedí s jádrem reaktoru.");
    return;
  }
  const it = heldItem(player);
  if (it?.typeId === `${NS}:uranium_fuel_rod`) {
    const r = insertFuel(key);
    if (r === "OK") {
      consumeHeld(player, 1);
      Logs.push("alarms", `Do reaktoru vložena palivová tyč (${player.name}).`);
      player.onScreenDisplay.setActionBar(`§aPalivová tyč vložena (${Machines.get(key).fuel}/4).`);
    } else player.onScreenDisplay.setActionBar(`§e${r}`);
    return;
  }
  const f = new ActionFormData().title(`§lŘídicí panel reaktoru – ${STATUS_CS[rec.status] ?? rec.status}`)
    .body(describeMachine(key, rec).join("\n") + "\n\n§7Palivo vložíte klepnutím na panel s uranovou palivovou tyčí.§r");
  const acts = [];
  f.button("§aSTART");
  acts.push(() => startReactor(key, player.name));
  f.button("§c§lSCRAM");
  acts.push(() => (scram(key, `řídicí panel (${player.name})`), "OK"));
  f.button("Reset");
  acts.push(() => resetReactor(key));
  f.button(`Automatická ochrana: ${rec.protect !== false ? "§azap.§r" : "§cvyp.§r"}`);
  acts.push(() => {
    rec.protect = rec.protect === false;
    Machines.save(key);
    return "OK";
  });
  f.button("Zavřít");
  const r = await f.show(player);
  if (r.canceled || r.selection === undefined || r.selection >= acts.length) return;
  const out = acts[r.selection]();
  player.sendMessage(out === "OK" ? "§a[Reaktor] Provedeno." : `§c[Reaktor] ${out}`);
  return openReactorPanel(player, block, key);
}

export async function openServer(player, block, key) {
  const rec = Machines.get(key);
  if (!rec) return;
  const vis = visibleMachines(key, rec);
  const pcs = vis.list.filter(([, v]) => info(v.rec.t)?.role === "computer");
  const body = [
    `Stav: ${rec.powered && !rec.shutdown ? "§aonline§r" : "§coffline§r"} (spotřeba 5)`,
    `Datová síť: ${vis.net ? vis.net.conduits + " kabelů, " + vis.net.machines.size + " zařízení" : "§cnepřipojeno§r"}`,
    `Připojené počítače (${pcs.length}): ${pcs.map(([k, v]) => machineLabel(k, v.rec)).join(", ") || "-"}`,
    `Zařízení v dosahu serveru: ${vis.list.length}`,
  ].join("\n");
  const f = new ActionFormData().title("§lServerový rack RadioÚstí").body(body);
  f.button("Vytisknout výpis záznamů");
  f.button("Vymazat historii alarmů");
  f.button(rec.shutdown ? "§aZapnout server" : "§cVypnout server");
  f.button("Zavřít");
  const r = await f.show(player);
  if (r.selection === 0) giveItem(player, `${NS}:document_printout`, 1);
  if (r.selection === 1) {
    Logs.clear("alarms");
    player.sendMessage("§7Historie alarmů vymazána.");
  }
  if (r.selection === 2) {
    rec.shutdown = !rec.shutdown;
    Machines.save(key);
  }
}

export async function openHandbook(player, page = -1) {
  if (page < 0) {
    const f = new ActionFormData().title("§lPříručka RadioÚstí").body("Zeds World • RadioÚstí 2072\nAutor add-onu: Jackhack2021");
    for (const ch of HANDBOOK) f.button(ch.title);
    f.button("Zavřít");
    const r = await f.show(player);
    if (r.canceled || r.selection === undefined || r.selection >= HANDBOOK.length) return;
    return openHandbook(player, r.selection);
  }
  const ch = HANDBOOK[page];
  const r = await new MessageFormData().title(ch.title).body(ch.text).button1("< Obsah").button2(page + 1 < HANDBOOK.length ? "Další >" : "Zavřít").show(player);
  if (r.selection === 0) return openHandbook(player, -1);
  if (r.selection === 1 && page + 1 < HANDBOOK.length) return openHandbook(player, page + 1);
}

export async function readDocument(player, docKey) {
  const d = DOCS[docKey];
  if (!d) return;
  sound(player.dimension, player.location, "radiousti.pc_click", 0.3, 0.6);
  await new ActionFormData().title(`§l${d.title}`).body(d.text).button("Zavřít").show(player);
}

export { isCreative, MessageFormData };
