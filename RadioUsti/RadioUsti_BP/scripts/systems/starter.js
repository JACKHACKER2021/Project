// Survival starter kit (given once per player on first join) and the radiation sensor (dosimeter).
// Again for yourself: /radiousti:starter_kit   ·   disable: /scriptevent radiousti:config starterkit off
import { world, system, ItemStack } from "@minecraft/server";
import { NS, heldItem } from "../lib/util.js";
import { Config } from "../lib/store.js";
import { getDose, lastRateOf, radiationLevel, RAD_LEVELS } from "./radiation.js";

/** @type {Array<[string, number]>} */
export const STARTER_KIT = [
  [`${NS}:gas_mask`, 1], [`${NS}:dosimeter`, 1], [`${NS}:canned_food`, 6], [`${NS}:mre_ration`, 2], [`${NS}:purified_water`, 4],
  [`${NS}:decontaminated_bread`, 4], [`${NS}:anti_radiation_pills`, 4], [`${NS}:handbook`, 1],
];

export function giveStarterKit(player) {
  const c = player.getComponent("minecraft:inventory")?.container;
  for (const [id, n] of STARTER_KIT) {
    const rest = c ? c.addItem(new ItemStack(id, n)) : new ItemStack(id, n);
    if (rest) player.dimension.spawnItem(rest, player.location);
  }
  player.setDynamicProperty("ru:starter_given", true);
  player.sendMessage("§a[Zeds Corp] Startovní balíček přeživšího: plynová maska, radiační senzor, konzervy, MRE, filtrovaná voda, chléb, tablety a příručka. Hodně štěstí v RadioÚstí.");
}

world.afterEvents.playerSpawn.subscribe((ev) => {
  if (!ev.initialSpawn || Config.get().starterKit === false) return;
  const p = ev.player;
  if (p.getDynamicProperty("ru:starter_given") === true) return;
  system.runTimeout(() => {
    try {
      giveStarterKit(p);
    } catch (e) {
      console.warn(`[RadioÚstí] starter kit: ${e}`);
    }
  }, 40);
});

/** Dosimeter reading line. */
export function dosimeterText(p) {
  const rate = lastRateOf(p);
  const dose = getDose(p);
  const lvl = radiationLevel(dose);
  const col = rate > 1 ? "§c" : rate > 0.3 ? "§6" : rate > 0.05 ? "§e" : "§a";
  return `${col}☢ ${rate.toFixed(2)} mSv/s §f| dávka ${dose.toFixed(0)}/150${lvl ? ` §c| Radiace ${RAD_LEVELS[lvl]}` : ""}`;
}

// continuous reading while the dosimeter is held in the hand
system.runInterval(() => {
  for (const p of world.getAllPlayers()) {
    if (heldItem(p)?.typeId === `${NS}:dosimeter`) p.onScreenDisplay.setActionBar(`§7[Dozimetr] ${dosimeterText(p)}`);
  }
}, 20);
