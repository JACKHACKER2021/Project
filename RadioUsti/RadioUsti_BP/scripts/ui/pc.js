// ÚstíOS Longhorn Edition - the interactive Old PC interface (stable @minecraft/server-ui forms).
// Inspired by the look of 2000s desktop previews; no third-party logos or trademarks are used.
import { world } from "@minecraft/server";
import { ActionFormData, MessageFormData } from "@minecraft/server-ui";
import { NS, info, parseKey, dimOf, countItem, sound, giveItem, fmtPos, dist2 } from "../lib/util.js";
import { Machines, Logs } from "../lib/store.js";
import { networkOf, machinesNear, scanNetwork, machineParts } from "../systems/network.js";
import { STATUS_CS, startReactor, scram, resetReactor } from "../systems/reactor.js";
import { radiationAt, countContaminated, getDose } from "../systems/radiation.js";
import { DOCS } from "../data/lore.js";
import { describeMachine, machineLabel } from "./describe.js";
import { setActive } from "../systems/network.js";
import { blockAt } from "../lib/util.js";

const OS = "§l§9ÚstíOS§r §7Longhorn Edition§r";
const LOCAL_RANGE = 8;
const SERVER_RANGE = 64;

/** Machines this computer can see: local radius + data network (+ server-wide range). */
export function visibleMachines(key, rec) {
  const p = parseKey(key);
  const seen = new Map();
  for (const [k, r] of machinesNear(p.dim, p, LOCAL_RANGE)) if (k !== key) seen.set(k, { rec: r, via: "okolí" });
  const net = networkOf(key, rec, "data");
  let server = false;
  if (net) {
    for (const k of net.machines) {
      const r = Machines.get(k);
      if (!r || k === key) continue;
      seen.set(k, { rec: r, via: "síť" });
      if (info(r.t)?.role === "server" && r.powered) server = true;
    }
  }
  if (server) for (const [k, r] of machinesNear(p.dim, p, SERVER_RANGE)) if (k !== key && !seen.has(k)) seen.set(k, { rec: r, via: "server" });
  return { list: [...seen.entries()], server, net };
}

async function msg(player, title, body) {
  await new ActionFormData().title(title).body(body).button("§l< Zpět").show(player);
}

export async function openComputer(player, block, key) {
  const rec = Machines.get(key);
  if (!rec) return;
  if (!rec.powered) {
    sound(block.dimension, block.location, "radiousti.pc_error", 0.7);
    await msg(player, OS, "§cŽádné napájení.§r\n\nPočítač potřebuje 2 jednotky energie. Připojte ho elektrickým kabelem k běžícímu generátoru nebo baterii.\n\nTip: Systémový analyzátor ukáže stav energetické sítě.");
    return;
  }
  if (rec.shutdown) {
    const r = await new MessageFormData().title(OS).body("Počítač je vypnutý.").button1("Zapnout").button2("Zavřít").show(player);
    if (r.selection === 0) {
      rec.shutdown = false;
      Machines.save(key);
      sound(block.dimension, block.location, "radiousti.pc_boot", 0.8);
      return openComputer(player, block, key);
    }
    return;
  }
  return desktop(player, block, key);
}

async function desktop(player, block, key) {
  const rec = Machines.get(key);
  const vis = visibleMachines(key, rec);
  const reactors = vis.list.filter(([, v]) => v.rec.t === `${NS}:reactor_core`);
  const t = world.getTimeOfDay();
  const hh = String(Math.floor(((t / 1000) + 6) % 24)).padStart(2, "0");
  const mm = String(Math.floor(((t % 1000) / 1000) * 60)).padStart(2, "0");
  const alarm = reactors.some(([, v]) => ["WARNING", "CRITICAL", "MELTDOWN"].includes(v.rec.status));
  const f = new ActionFormData().title(OS);
  f.body(
    `§bPlocha§r – přihlášen: §f${player.name}§r   §7${hh}:${mm}§r\n` +
      `Napájení: §aOK§r (síť ${rec.net?.supply ?? 0}/${rec.net?.demand ?? 0})   Server: ${vis.server ? "§apřipojen§r" : "§7nedostupný§r"}\n` +
      `Viditelné stroje: ${vis.list.length}   Reaktory: ${reactors.length}${alarm ? "   §c§l! POPLACH !§r" : ""}`
  );
  /** @type {Array<[string, () => Promise<any>]>} */
  const items = [
    ["Stav systému", () => systemStatus(player, block, key, vis)],
    ["Napájení", () => powerView(player, block, key, vis)],
    ["Připojené stroje", () => machinesView(player, block, key, vis)],
    [`Dohled reaktoru${reactors.length ? "" : " §8(žádný reaktor)"}`, () => reactorView(player, block, key, vis)],
    ["Diagnostika potrubí a kabelů", () => diagnostics(player, block, key, vis)],
    ["Historie alarmů", () => logView(player, block, key, "alarms", "Historie alarmů")],
    ["Dokumenty RadioÚstí", () => documents(player, block, key)],
    ["Laboratorní záznamy", () => logView(player, block, key, "lab", "Laboratorní záznamy")],
    ["Zprávy o kontaminaci", () => contamination(player, block, key)],
    [`Síť a server${vis.server ? "" : " §8(omezeno)"}`, () => networkView(player, block, key, vis)],
    ["Přehrávač VHS", () => vhs(player, block, key)],
    ["Vypnout / Restartovat", () => power(player, block, key)],
  ];
  for (const [label] of items) f.button(label);
  sound(block.dimension, block.location, "radiousti.pc_click", 0.5);
  const res = await f.show(player);
  if (res.canceled || res.selection === undefined) return;
  await items[res.selection][1]();
}

async function back(player, block, key) {
  return desktop(player, block, key);
}

async function systemStatus(player, block, key, vis) {
  const rec = Machines.get(key);
  const p = parseKey(key);
  const body = [
    "§lÚstíOS build 4074§r (Longhorn Edition)",
    `Stanice: ${info(rec.t)?.cs} na ${fmtPos(p)}`,
    `Napájení: ${rec.powered ? "§aano§r" : "§cne§r"}`,
    `Datová síť: ${vis.net ? vis.net.conduits + " kabelů, " + vis.net.machines.size + " zařízení" : "nepřipojeno"}`,
    `Server: ${vis.server ? "§adostupný – dosah 64 bloků§r" : "§7nedostupný – dosah 8 bloků + síť§r"}`,
    `Uživatel: ${player.name}, dávka radiace ${getDose(player).toFixed(0)}`,
  ].join("\n");
  await msg(player, OS + " – Stav systému", body);
  return back(player, block, key);
}

async function powerView(player, block, key, vis) {
  const L = [];
  const rec = Machines.get(key);
  L.push(`Tato stanice: výroba ${rec.net?.supply ?? 0}, spotřeba ${rec.net?.demand ?? 0}`);
  for (const [k, v] of vis.list) {
    const i = info(v.rec.t);
    if (i?.role === "generator") L.push(`${machineLabel(k, v.rec)}: ${v.rec.running ? "§abeží " + v.rec.output + "§r" : "§cstojí§r"}`);
    if (i?.role === "battery") L.push(`${machineLabel(k, v.rec)}: ${v.rec.charge ?? 0}/${i.capacity}`);
  }
  if (L.length === 1) L.push("§7Žádné viditelné zdroje energie.§r");
  await msg(player, OS + " – Napájení", L.join("\n"));
  return back(player, block, key);
}

async function machinesView(player, block, key, vis) {
  const f = new ActionFormData().title(OS + " – Připojené stroje");
  const list = vis.list.slice(0, 30);
  f.body(list.length ? `Nalezeno ${vis.list.length} zařízení.` : "§7Žádná zařízení v dosahu. Připojte stroje síťovým kabelem.§r");
  for (const [k, v] of list) f.button(`${machineLabel(k, v.rec)}\n§7přes ${v.via}`);
  f.button("§l< Zpět");
  const r = await f.show(player);
  if (r.canceled || r.selection === undefined) return;
  if (r.selection < list.length) {
    const [k, v] = list[r.selection];
    await msg(player, machineLabel(k, v.rec), describeMachine(k, v.rec).join("\n"));
    return machinesView(player, block, key, vis);
  }
  return back(player, block, key);
}

async function reactorView(player, block, key, vis) {
  const reactors = vis.list.filter(([, v]) => v.rec.t === `${NS}:reactor_core`);
  if (!reactors.length) {
    await msg(player, OS + " – Dohled reaktoru", "§7Funkce nedostupná: v dosahu ani v datové síti není žádný reaktor.\nPřipojte řídicí panel nebo plášť reaktoru síťovým kabelem.§r");
    return back(player, block, key);
  }
  const f = new ActionFormData().title(OS + " – Dohled reaktoru");
  for (const [k, v] of reactors) f.button(`${machineLabel(k, v.rec)}\n${STATUS_CS[v.rec.status] ?? v.rec.status} – ${v.rec.heat ?? 0} %`);
  f.button("§l< Zpět");
  const r = await f.show(player);
  if (r.canceled || r.selection === undefined) return;
  if (r.selection >= reactors.length) return back(player, block, key);
  const [rk, rv] = reactors[r.selection];
  const remote = rv.via === "síť" || rv.via === "server";
  const g = new ActionFormData().title(machineLabel(rk, rv.rec)).body(describeMachine(rk, Machines.get(rk)).join("\n"));
  const acts = [];
  g.button(remote ? "§aSpustit reaktor" : "§8Spustit (jen přes datovou síť)");
  acts.push(() => (remote ? startReactor(rk, player.name) : "Dálkové spuštění vyžaduje připojení síťovým kabelem."));
  g.button("§cSCRAM – nouzové odstavení");
  acts.push(() => (scram(rk, `ÚstíOS (${player.name})`), "OK"));
  g.button("Reset po odstavení");
  acts.push(() => resetReactor(rk));
  g.button("§l< Zpět");
  const s = await g.show(player);
  if (s.canceled || s.selection === undefined || s.selection >= acts.length) return reactorView(player, block, key, vis);
  const out = acts[s.selection]();
  player.sendMessage(out === "OK" ? "§a[ÚstíOS] Příkaz proveden." : `§c[ÚstíOS] ${out}`);
  return reactorView(player, block, key, visibleMachines(key, Machines.get(key)));
}

async function diagnostics(player, block, key, vis) {
  const L = [];
  const p = parseKey(key);
  const dim = dimOf(p.dim);
  for (const [k, v] of vis.list.slice(0, 16)) {
    const i = info(v.rec.t);
    const fams = [];
    if (i?.family) fams.push(i.family);
    if (["generator", "battery", "computer", "server", "station"].includes(i?.role)) fams.push("power");
    const parts = machineParts(k, v.rec);
    const bits = fams.map((fam) => {
      const n = scanNetwork(dim, parts, fam);
      return `${fam}: ${n.conduits} úseků${n.closedValves ? ", §czavřené ventily " + n.closedValves + "§r" : ""}${n.damaged ? ", §cpoškozené kabely " + n.damaged + "§r" : ""}`;
    });
    L.push(`${machineLabel(k, v.rec)}\n  ${bits.join("; ") || "bez připojení"}`);
  }
  await msg(player, OS + " – Diagnostika", L.length ? L.join("\n") : "§7Žádná zařízení k diagnostice.§r");
  return back(player, block, key);
}

async function logView(player, block, key, channel, title) {
  const logs = Logs.get(channel);
  const f = new ActionFormData().title(`${OS} – ${title}`).body(logs.length ? logs.slice(0, 20).join("\n") : "§7Žádné záznamy.§r");
  f.button("§l< Zpět");
  f.button("Vymazat záznamy");
  const r = await f.show(player);
  if (r.selection === 1) Logs.clear(channel);
  if (r.canceled) return;
  return back(player, block, key);
}

async function documents(player, block, key) {
  const entries = Object.entries(DOCS);
  const f = new ActionFormData().title(OS + " – Dokumenty RadioÚstí");
  for (const [, d] of entries) f.button(d.title);
  f.button("Vytisknout výpis systému");
  f.button("§l< Zpět");
  const r = await f.show(player);
  if (r.canceled || r.selection === undefined) return;
  if (r.selection < entries.length) {
    await msg(player, entries[r.selection][1].title, entries[r.selection][1].text);
    return documents(player, block, key);
  }
  if (r.selection === entries.length) {
    giveItem(player, `${NS}:document_printout`, 1);
    player.sendMessage("§a[ÚstíOS] Výpis vytištěn.");
  }
  return back(player, block, key);
}

async function contamination(player, block, key) {
  const lvl = radiationAt(block.dimension, block.location, 6);
  const n = countContaminated(block.dimension, block.location, 8);
  const logs = Logs.get("contamination");
  await msg(player, OS + " – Kontaminace",
    `Aktuální měření u stanice: radiace §e${lvl.toFixed(2)}§r, radioaktivních bloků v okruhu 8: §e${n < 0 ? "?" : n}§r\n\n` +
      (logs.length ? logs.slice(0, 15).join("\n") : "§7Žádné zprávy o kontaminaci.§r"));
  return back(player, block, key);
}

async function networkView(player, block, key, vis) {
  const servers = vis.list.filter(([, v]) => info(v.rec.t)?.role === "server");
  const pcs = vis.list.filter(([, v]) => info(v.rec.t)?.role === "computer");
  const L = [
    `Datová síť: ${vis.net ? vis.net.conduits + " kabelů" : "§cnepřipojeno§r"}`,
    `Servery: ${servers.length ? servers.map(([k, v]) => `${machineLabel(k, v.rec)} ${v.rec.powered ? "§aonline§r" : "§coffline§r"}`).join(", ") : "§7žádný§r"}`,
    `Ostatní počítače: ${pcs.length}`,
  ];
  if (!vis.server) L.push("\n§7Bez napájeného serveru ve stejné datové síti je dosah omezen na 8 bloků a přímo připojené stroje.§r");
  await msg(player, OS + " – Síť a server", L.join("\n"));
  return back(player, block, key);
}

async function vhs(player, block, key) {
  if (countItem(player, `${NS}:vhs_radiousti`) < 1) {
    await msg(player, OS + " – Přehrávač VHS", "§7Vložte kazetu: mějte v inventáři VHS kazetu RadioÚstí 2072.§r");
    return back(player, block, key);
  }
  try {
    player.playSound("radiousti.record_radiousti", { volume: 1 });
  } catch {
    /* sound unavailable */
  }
  await msg(player, OS + " – Přehrávač VHS", "▶ Přehrává se: RadioÚstí 2072 (VHS, 24 s)");
  return back(player, block, key);
}

async function power(player, block, key) {
  const r = await new MessageFormData().title(OS).body("Co chcete udělat?").button1("Vypnout").button2("Restartovat").show(player);
  const rec = Machines.get(key);
  if (r.selection === 0) {
    rec.shutdown = true;
    Machines.save(key);
    setActive({ dim: block.dimension, block, info: info(block.typeId), pos: block.location }, false);
    player.sendMessage("§7[ÚstíOS] Počítač vypnut.");
  } else if (r.selection === 1) {
    sound(block.dimension, block.location, "radiousti.pc_boot", 0.8);
    player.sendMessage("§7[ÚstíOS] Restart…");
  }
}

export { blockAt, dist2 };
