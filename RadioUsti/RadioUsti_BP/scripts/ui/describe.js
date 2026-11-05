// Shared, registry-driven status descriptions (used by the System Analyzer, machine panels and ÚstíOS).
import { NS, info, parseKey, dimOf } from "../lib/util.js";
import { Machines } from "../lib/store.js";
import { STATUS_CS, reactorReport, MAX_FUEL } from "../systems/reactor.js";

export const KIND_CS = {
  pipe: "potrubí", valve: "ventil", cable: "kabel", machine: "stroj", reactor_shell: "část reaktoru", reactor_port: "port reaktoru",
  door: "dveře", light: "světlo", alarm: "alarm", indicator: "indikátor", radioactive: "radioaktivní materiál", decor: "dekorace",
  furniture: "nábytek", document: "dokument", clock: "hodiny", jar: "laboratorní nádoba", organic: "organický materiál", soul: "duše",
  control: "ovládací prvek", glassware: "laboratorní sklo", craft_table: "pracovní stůl", station: "laboratorní stanice",
};

export const FAMILY_CS = {
  water: "voda", gas: "plyn", molten: "roztavený materiál", radioactive: "radioaktivní kapalina", oil: "olej", power: "elektřina", data: "data",
};

export const OIL_CS = {
  industrial: "průmyslový olej", black: "černý strojní olej", hydraulic: "žlutý hydraulický olej", lab: "červený laboratorní olej",
  contaminated: "zelený kontaminovaný olej", radioactive: "radioaktivní olej",
};

const yes = (b) => (b ? "§aano§r" : "§cne§r");

function bar(v, max, len = 20) {
  const n = Math.max(0, Math.min(len, Math.round((v / max) * len)));
  return "§a" + "|".repeat(n) + "§8" + "|".repeat(len - n) + "§r";
}

/** Status lines for a registered machine record. */
export function describeMachine(key, rec) {
  const i = info(rec.t) ?? {};
  const L = [];
  const net = rec.net;
  if (i.role === "generator") {
    L.push(`Provoz: ${rec.running ? "§aběží§r" : "§cstojí§r"}${rec.on === false ? " (vypnuto obsluhou)" : ""}`);
    L.push(`Výkon: ${rec.output ?? 0} / ${i.output} jednotek`);
    if (rec.t === `${NS}:generator_nuclear`) L.push(`Napájení z reaktoru: ${yes(rec.reactorFeed)}`);
    else if (rec.t === `${NS}:generator_industrial`) L.push(`Zdroj: ${rec.source === "molten" ? "roztavený materiál" : rec.source === "gas" ? "plyn" : "§cžádný (připojte lávu nebo plynovou nádrž)§r"}`);
    else L.push(`Palivo: ${rec.fuel ?? 0} cyklů (${Math.round((rec.fuel ?? 0) * 2)} s)${i.backup ? " – záložní, startuje jen při nedostatku" : ""}`);
    if ((rec.fuel ?? 0) <= 0 && !rec.running && rec.t !== `${NS}:generator_nuclear` && rec.t !== `${NS}:generator_industrial`) L.push("§eProblém: chybí palivo.§r");
  } else if (i.role === "battery") {
    L.push(`Nabití: ${rec.charge ?? 0} / ${i.capacity} ${bar(rec.charge ?? 0, i.capacity)}`);
    L.push(`Tok: ${rec.flow > 0 ? "nabíjí +" + rec.flow : rec.flow < 0 ? "vybíjí " + rec.flow : "0"}`);
  } else if (i.role === "reactor") {
    const r = reactorReport(key);
    L.push(`Stav: §l${STATUS_CS[rec.status] ?? rec.status}§r`);
    L.push(`Teplota: ${rec.heat ?? 0} % ${bar(rec.heat ?? 0, 100)}`);
    L.push(`Palivo: ${rec.fuel ?? 0}/${MAX_FUEL} tyčí, aktuální tyč ${Math.round(((rec.burn ?? 0) * 2) / 60)} min`);
    L.push(`Odpad v reaktoru: ${rec.waste ?? 0}${rec.leak ? " §c– ÚNIK§r" : ""}`);
    L.push(`Automatická ochrana: ${yes(rec.protect !== false)}`);
    if (r) {
      L.push(`Stavba: ${r.structure.ok ? "§akompletní§r" : "§cneúplná§r"}`);
      for (const p of r.structure.problems.slice(0, 4)) L.push(`  §c- ${p}§r`);
      L.push(`Chlazení: ${yes(r.coolant.ok)} (jednotek ${r.coolant.units}, zdroj vody ${r.coolant.source ? "ano" : "ne"}, zavřených ventilů ${r.coolant.closedValves})`);
      L.push(`Kontejnery odpadu: ${r.containers.length}`);
    }
  } else if (i.role === "tank") {
    if (i.family === "gas") L.push(`Plyn: ${rec.gas ?? 0} / ${i.capacity} ${bar(rec.gas ?? 0, i.capacity)}`);
    else L.push(`${OIL_CS[i.oil] ?? "olej"}: ${rec.amount ?? 0} / ${i.capacity} kanystrů`);
  } else if (i.role === "waste_sink") {
    L.push(`Odpad: ${rec.waste ?? 0} / ${i.capacity} ${bar(rec.waste ?? 0, i.capacity)}`);
  } else if (i.role === "source") {
    L.push(`Čerpá vodu: ${yes(rec.ok)}${rec.ok ? "" : " (položte čerpadlo k vodnímu bloku)"}`);
  } else if (i.role === "cooler") {
    L.push("Chladicí jednotka – musí být ve vodní síti s chladicím portem a zdrojem vody.");
  } else if (i.role === "computer" || i.role === "server" || i.role === "station") {
    L.push(`Napájení: ${yes(rec.powered)} (spotřeba ${i.demand ?? 0})${rec.shutdown ? " – vypnutý" : ""}`);
    if (i.station === "chemical") L.push(`Náplň činidel: ${rec.charges ?? 0}`);
  } else if (i.kind === "alarm") {
    L.push(`Důvod: ${rec.why ?? "-"}`);
  } else if (i.kind === "indicator") {
    L.push(`Úroveň radiace: ${rec.level ?? 0}/3 (${rec.value ?? 0})`);
  } else if (i.kind === "light") {
    L.push(`Ruční zapnutí: ${yes(rec.manual)}, automatika: ${yes(rec.autoActive)}`);
  }
  if (net && (i.role !== undefined)) L.push(`Energetická síť: výroba ${net.supply}${net.redstone ? ` (z toho redstone ${net.redstone})` : ""}, spotřeba ${net.demand}, strojů ${net.members}`);
  return L;
}

export function machineLabel(key, rec) {
  const p = parseKey(key);
  return `${info(rec.t)?.cs ?? rec.t} [${p.x} ${p.y} ${p.z}]`;
}

export { Machines, dimOf };
