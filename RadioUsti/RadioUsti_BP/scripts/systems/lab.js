// Laboratory stations: script-driven processing with real inputs, outputs, power and gas checks.
import { ActionFormData } from "@minecraft/server-ui";
import { NS, ITEMS, countItem, takeItem, giveItem, sound, name, isCreative } from "../lib/util.js";
import { Machines, Logs } from "../lib/store.js";
import { pullGas } from "./network.js";
import { radiationAt, countContaminated, getDose, setDose } from "./radiation.js";

const I = (s) => (s.includes(":") ? s : `${NS}:${s}`);

const RECIPES = {
  prep: [
    { label: "Krev → vzorky krve", needs: [["blood_bottle", 1], ["empty_test_tube", 2]], gives: [["blood_sample", 2], ["minecraft:glass_bottle", 1]] },
    { label: "Infikované maso → vzorek tkáně", needs: [["infected_flesh", 1], ["sample_container", 1]], gives: [["tissue_sample", 1]] },
    { label: "Kontaminovaná hlína → vzorek půdy", needs: [["contaminated_dirt", 1], ["sample_container", 1]], gives: [["soil_sample", 1]] },
    { label: "Nádoba s krví → 2 láhve krve", needs: [["blood_jar", 1], ["minecraft:glass_bottle", 2]], gives: [["blood_bottle", 2], ["empty_jar", 1]] },
  ],
  bio: [
    { label: "Analýza vzorku krve", needs: [["blood_sample", 1], ["reagent_flask_blue", 1]], gives: [["document_research_record", 1], ["empty_flask", 1], ["lab_waste", 1]],
      power: true, bonus: [["zed_serum", 1, 0.3]], log: ["lab", "Krevní vzorek: nalezen kmen Zed-72, protilátky {serum}."] },
    { label: "Analýza vzorku tkáně", needs: [["tissue_sample", 1], ["reagent_flask_blue", 1]], gives: [["organic_material", 2], ["empty_flask", 1], ["lab_waste", 1]],
      power: true, log: ["lab", "Vzorek tkáně: buněčná nekróza, aktivní infekce Zed."] },
  ],
  chemical: [
    { label: "Syntéza antiradiačních tablet", needs: [["reagent_flask_green", 1], ["minecraft:dried_kelp", 2]], gives: [["anti_radiation_pills", 3], ["empty_flask", 1]],
      power: true, gas: 2, charges: 1, log: ["lab", "Syntetizovány antiradiační tablety (3 ks)."] },
    { label: "Chemická analýza krve", needs: [["blood_sample", 1], ["reagent_flask_red", 1]], gives: [["document_lab_report", 1], ["empty_flask", 1]],
      power: true, gas: 1, charges: 1, log: ["lab", "Chemická analýza krve: zvýšené těžké kovy, stopy uranu."] },
  ],
  nuclear: [
    { label: "Výroba uranové palivové tyče", needs: [["uranium_ingot", 2], ["canister_radioactive_oil", 1]], gives: [["uranium_fuel_rod", 1], ["empty_canister", 1]],
      power: true, log: ["lab", "Vyrobena uranová palivová tyč."] },
    { label: "Obohacení surového uranu", needs: [["raw_uranium", 4], ["canister_lab_oil", 1]], gives: [["uranium_ingot", 3], ["empty_canister", 1], ["lab_waste", 1]],
      power: true },
  ],
  contamination: [
    { label: "Test vzorku půdy", needs: [["soil_sample", 1], ["reagent_flask_red", 1]], gives: [["document_contamination_report", 1], ["empty_flask", 1]],
      power: true, special: "soil" },
    { label: "Dekontaminace oleje", needs: [["canister_contaminated_oil", 1], ["reagent_flask_green", 1]], gives: [["canister_industrial_oil", 1], ["empty_flask", 1], ["lab_waste", 1]],
      power: true, log: ["contamination", "Dekontaminován kanystr zeleného oleje."] },
    { label: "Dekontaminace osoby (−25 dávky)", needs: [["reagent_flask_green", 1]], gives: [["empty_flask", 1]], power: true, special: "person" },
  ],
};

export const STATION_TITLES = {
  prep: "Stůl přípravy vzorků", bio: "Stůl biologického výzkumu", chemical: "Stůl chemické analýzy",
  nuclear: "Stůl jaderného výzkumu", contamination: "Stanice testování kontaminace",
};

function have(player, rec) {
  return rec.needs.every(([id, n]) => isCreative(player) || countItem(player, I(id)) >= n);
}

function status(key, m, r) {
  const probs = [];
  if (r.power && !m.powered) probs.push("bez napájení");
  if (r.charges && (m.charges ?? 0) < r.charges) probs.push("chybí náplň červeného oleje");
  return probs;
}

export async function openStation(player, block, key, station) {
  const m = Machines.get(key);
  const list = RECIPES[station] ?? [];
  const f = new ActionFormData().title(`§l${STATION_TITLES[station]}`);
  const power = m.powered ? "§aNapájeno" : "§cBez napájení";
  let body = `${power}§r`;
  if (station === "chemical") body += `\nNáplň činidel: §e${m.charges ?? 0}§r (doplníte kanystrem červeného laboratorního oleje)\nPlyn: připojte laboratorní plynové potrubí k plynové nádrži.`;
  if (station === "prep") body = "§7Nepotřebuje napájení.§r";
  f.body(body);
  const actions = [];
  for (const r of list) {
    const probs = status(key, m, r);
    const ok = have(player, r) && probs.length === 0;
    const needs = r.needs.map(([id, n]) => `${n}× ${name(I(id))}`).join(", ");
    f.button(`${ok ? "§2" : "§8"}${r.label}\n§r§7${needs}${probs.length ? " – " + probs.join(", ") : ""}`);
    actions.push(() => run(player, block, key, station, r));
  }
  if (station === "chemical") {
    f.button("Doplnit činidla (kanystr červeného oleje)");
    actions.push(() => {
      if (!takeItem(player, `${NS}:canister_lab_oil`, 1)) return player.sendMessage("§cPotřebujete Kanystr – červený laboratorní olej.");
      m.charges = (m.charges ?? 0) + 8;
      Machines.save(key);
      giveItem(player, `${NS}:empty_canister`, 1);
      player.sendMessage(`§aNáplň doplněna: ${m.charges} analýz.`);
    });
  }
  if (station === "nuclear" || station === "contamination") {
    f.button("Měření radiace v okolí");
    actions.push(() => {
      const lvl = radiationAt(block.dimension, block.location, 6);
      const n = countContaminated(block.dimension, block.location, 8);
      player.sendMessage(`§e[${STATION_TITLES[station]}] §fRadiace v okruhu 6 bloků: §e${lvl.toFixed(2)}§f, radioaktivních bloků v okruhu 8: §e${n < 0 ? "?" : n}`);
    });
  }
  f.button("§8Zavřít");
  const res = await f.show(player);
  if (res.canceled || res.selection === undefined) return;
  actions[res.selection]?.();
}

function run(player, block, key, station, r) {
  const m = Machines.get(key);
  const probs = status(key, m, r);
  if (probs.length) return player.sendMessage(`§c${STATION_TITLES[station]}: ${probs.join(", ")}.`);
  if (!have(player, r)) return player.sendMessage("§cNemáte potřebné suroviny: " + r.needs.map(([id, n]) => `${n}× ${name(I(id))}`).join(", "));
  if (r.gas && !pullGas(key, m, r.gas)) return player.sendMessage("§cStůl nemá přívod plynu (laboratorní/plynové potrubí → plynová nádrž s plynem, otevřené ventily).");
  for (const [id, n] of r.needs) takeItem(player, I(id), n);
  if (r.charges) {
    m.charges -= r.charges;
    Machines.save(key);
  }
  for (const [id, n] of r.gives) giveItem(player, I(id), n);
  let serum = "nenalezeny";
  for (const [id, n, chance] of r.bonus ?? []) {
    if (Math.random() < chance) {
      giveItem(player, I(id), n);
      serum = "izolovány – vytvořeno sérum";
    }
  }
  if (r.special === "soil") {
    const lvl = radiationAt(block.dimension, block.location, 6);
    const n = countContaminated(block.dimension, block.location, 8);
    Logs.push("contamination", `Test půdy u ${block.location.x} ${block.location.y} ${block.location.z}: radiace ${lvl.toFixed(2)}, zamořených bloků ${n}.`);
  }
  if (r.special === "person") {
    setDose(player, getDose(player) - 25);
    player.sendMessage(`§aDekontaminace hotova. Dávka: ${getDose(player).toFixed(0)}.`);
  }
  if (r.log) Logs.push(r.log[0], r.log[1].replace("{serum}", serum));
  sound(block.dimension, block.location, "radiousti.lab_process", 1);
  player.sendMessage(`§a${r.label}: hotovo.`);
}

export { ITEMS };
