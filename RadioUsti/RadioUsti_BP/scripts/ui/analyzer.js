// RadioÚstí System Analyzer: one registry-driven inspector for every block.
import { ActionFormData } from "@minecraft/server-ui";
import { NS, DIRS6, add, blockAt, info, stateOf, name, sound, fmtPos } from "../lib/util.js";
import { Machines } from "../lib/store.js";
import { isConduit, conduitLinks, familyOf, storedDirs } from "../systems/connections.js";
import { machineKeyForBlock, ensureMachine, scanNetwork, waterSource, findCoreNear } from "../systems/network.js";
import { originOf, missingParts } from "../systems/structures.js";
import { checkStructure } from "../systems/reactor.js";
import { radiationAt } from "../systems/radiation.js";
import { describeMachine, KIND_CS, FAMILY_CS } from "./describe.js";

const DIR_CS = { n: "sever", s: "jih", e: "východ", w: "západ", u: "nahoru", d: "dolů" };

export function inspectLines(block) {
  const L = [];
  const i = info(block.typeId);
  const dim = block.dimension;
  L.push(`§lBlok:§r ${name(block.typeId)}  §7(${block.typeId})§r`);
  L.push(`Pozice: ${fmtPos(block.location)}`);
  L.push(`Typ: ${i ? KIND_CS[i.kind] ?? i.kind : "vanilla blok"}`);

  if (i && isConduit(block.typeId)) {
    const fam = familyOf(block.typeId);
    L.push(`Rodina: ${FAMILY_CS[fam] ?? fam}`);
    const links = [];
    for (const d of DIRS6) {
      const nb = blockAt(dim, add(block.location, d));
      if (nb && conduitLinks(block.typeId, nb.typeId)) links.push(`${DIR_CS[d.k]}: ${name(nb.typeId)}`);
    }
    L.push(`Propojení (${links.length}): ${links.length ? "" : "§cžádné§r"}`);
    const st = storedDirs(block).map((k) => DIR_CS[k]);
    L.push(`§7Uložený tvar bloku: ${st.length ? st.join(", ") : "jen střed"}${st.length !== links.length ? " §c(nesouhlasí – opraví se do 3 s)§7" : ""}§r`);
    for (const l of links) L.push(`  • ${l}`);
    if (i.kind === "valve") L.push(`Ventil: ${stateOf(block, `${NS}:open`, true) ? "§aOTEVŘENO§r" : "§cZAVŘENO§r"}`);
    if (i.damaged) L.push("§cKabel je poškozený: připojí se, ale nepřenáší energii.§r");
    const net = scanNetwork(dim, [block.location], fam);
    L.push(`Síť: ${net.conduits + 1} úseků, ${net.machines.size} strojů, zavřené ventily ${net.closedValves}, poškozené kabely ${net.damaged}${net.truncated ? ", §esíť je příliš dlouhá§r" : ""}`);
    if (fam === "power") L.push(`Redstone v síti: ${net.redstone ? "§a" + net.redstone + " jednotek§r (zdrojů " + net.redstoneSources + ")" : "§7žádný§r"}`);
    if (fam === "water") L.push(`Zdroj vody v síti: ${waterSource(net) ? "§aano§r" : "§cne§r"}`);
    if (fam === "molten") L.push(`Láva v síti: ${net.vanilla.has("minecraft:lava") ? "§aano§r" : "§cne§r"}`);
    if (net.machines.size) {
      L.push("Připojené stroje:");
      for (const mk of [...net.machines].slice(0, 6)) {
        const r = Machines.get(mk);
        if (r) L.push(`  • ${info(r.t)?.cs ?? r.t}`);
      }
    }
  }

  if (i?.multiblock) {
    const part = stateOf(block, `${NS}:part`, 0);
    const o = originOf(block);
    const dir = stateOf(block, "minecraft:cardinal_direction", "north");
    const miss = missingParts(dim, block.typeId, o, dir);
    L.push(`Multiblok: část ${part + 1}/${i.multiblock.length}, počátek ${fmtPos(o)}, ${miss.length ? "§cchybí části " + miss.join(", ") + "§r" : "§akompletní§r"}`);
  }

  if (i && (i.kind === "machine" || i.kind === "alarm" || i.kind === "indicator" || (i.kind === "light" && i.auto))) {
    const [key, rec] = ensureMachine(block);
    if (rec) {
      L.push("§l— Stav stroje —§r");
      L.push(...describeMachine(key, rec));
      if (rec.net === undefined && (i.role === "generator" || i.demand)) L.push("§7(Síť se vyhodnotí do 2 sekund.)§r");
    }
  }

  if (i && (i.kind === "reactor_shell" || i.kind === "reactor_port")) {
    const core = findCoreNear(dim, block.location);
    if (!core) L.push("§cTento blok nesousedí s jádrem reaktoru.§r");
    else {
      const s = checkStructure(dim, core);
      L.push(`Jádro: ${fmtPos(core)} – stavba ${s.ok ? "§akompletní§r" : "§cneúplná§r"}`);
      for (const p of s.problems.slice(0, 4)) L.push(`  §c- ${p}§r`);
      const key = machineKeyForBlock(block);
      const rec = key && Machines.get(key);
      if (rec) L.push(...describeMachine(key, rec));
    }
    if (i.kind === "reactor_port") L.push(`Port pro: ${FAMILY_CS[i.family]}`);
  }

  if (i?.kind === "door") {
    L.push(`Dveře: ${stateOf(block, `${NS}:open`, false) ? "otevřené" : "zavřené"}, ${stateOf(block, `${NS}:upper`, false) ? "horní" : "dolní"} polovina`);
  }
  if (i?.kind === "light") L.push(`Světlo: ${stateOf(block, `${NS}:lit`, false) ? "§esvítí§r" : "zhasnuto"}`);
  if (i?.kind === "jar") L.push(`Náplň: ${["prázdná", "krev", "maso", "duše"][stateOf(block, `${NS}:fill`, 0)]}`);

  const rad = radiationAt(dim, block.location, 3);
  L.push(`Radiace v okolí (r=3): ${rad > 0.05 ? "§e" + rad.toFixed(2) + "§r" : "§a0§r"}`);
  if (i?.kind === "radioactive") L.push(`Kontaminace: §eano§r (intenzita ${i.rad})${i.clean ? " – lze vyčistit dekontaminační soupravou" : ""}`);
  return L;
}

export async function showInspection(player, block) {
  sound(block.dimension, block.location, "radiousti.scanner_beep", 0.8);
  const lines = inspectLines(block);
  const f = new ActionFormData().title("§lSystémový analyzátor RadioÚstí").body(lines.join("\n")).button("Zavřít");
  await f.show(player);
}
