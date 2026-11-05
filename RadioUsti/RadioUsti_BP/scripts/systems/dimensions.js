// Contaminated sphere: the Nether, the End and every other non-overworld dimension (including future
// or custom ones) are closed. Portal lighting and End-portal eyes are blocked; anyone who still ends up
// in another dimension is returned to the overworld. The first blocked attempt gives each player a
// Zeds Corp supply chest with the items normally found in the Nether and the End.
// Config: /scriptevent radiousti:config dimensions on   (re-opens other dimensions)
import { world, system, ItemStack, BlockPermutation } from "@minecraft/server";
import { blockAt, sound } from "../lib/util.js";
import { Config } from "../lib/store.js";

const OVERWORLD = "minecraft:overworld";
const IGNITERS = new Set(["minecraft:flint_and_steel", "minecraft:fire_charge"]);
/** @type {Array<[string, number]>} */
const SUPPLY = [
  ["minecraft:blaze_rod", 6], ["minecraft:blaze_powder", 4], ["minecraft:ender_pearl", 8], ["minecraft:nether_wart", 6],
  ["minecraft:glowstone_dust", 16], ["minecraft:quartz", 16], ["minecraft:ghast_tear", 2], ["minecraft:magma_cream", 4],
  ["minecraft:netherite_scrap", 2], ["minecraft:soul_sand", 8], ["minecraft:shulker_shell", 2], ["minecraft:chorus_fruit", 8],
  ["minecraft:dragon_breath", 2], ["minecraft:elytra", 1],
];

function closed() {
  return Config.get().dimensionsOpen !== true;
}

function warn(player) {
  player.onScreenDisplay.setTitle("§2☣ KONTAMINOVANÁ SFÉRA", { subtitle: "§7Portály do jiných dimenzí jsou uzavřeny", fadeInDuration: 0, stayDuration: 50, fadeOutDuration: 10 });
  sound(player.dimension, player.location, "radiousti.pc_error", 1);
}

function giveSupplyChest(player) {
  if (player.getDynamicProperty("ru:supply_given") === true) return;
  player.setDynamicProperty("ru:supply_given", true);
  system.run(() => {
    const l = player.location;
    const spots = [{ x: 1, z: 0 }, { x: -1, z: 0 }, { x: 0, z: 1 }, { x: 0, z: -1 }, { x: 1, z: 1 }];
    for (const s of spots) {
      const b = blockAt(player.dimension, { x: l.x + s.x, y: l.y, z: l.z + s.z });
      if (!b || !b.isAir) continue;
      try {
        b.setPermutation(BlockPermutation.resolve("minecraft:chest"));
        const c = b.getComponent("minecraft:inventory")?.container;
        for (const [id, n] of SUPPLY) c?.addItem(new ItemStack(id, n));
        player.sendMessage("§a[Zeds Corp] Doručena zásobovací bedna s materiálem z uzavřených dimenzí.");
        return;
      } catch {
        /* try next spot */
      }
    }
    for (const [id, n] of SUPPLY) {
      try {
        player.dimension.spawnItem(new ItemStack(id, n), l);
      } catch {
        /* ignore */
      }
    }
    player.sendMessage("§a[Zeds Corp] Zásoby z uzavřených dimenzí leží u tvých nohou.");
  });
}

// block lighting nether portals and filling end portal frames
world.beforeEvents.playerInteractWithBlock.subscribe((ev) => {
  if (!closed()) return;
  const id = ev.itemStack?.typeId;
  const t = ev.block.typeId;
  const portalTry = (IGNITERS.has(id) && (t === "minecraft:obsidian" || t === "minecraft:crying_obsidian")) ||
    (id === "minecraft:ender_eye" && t === "minecraft:end_portal_frame");
  if (!portalTry) return;
  ev.cancel = true;
  if (!ev.isFirstEvent) return;
  const p = ev.player;
  system.run(() => {
    warn(p);
    giveSupplyChest(p);
  });
});

// anyone who reaches another dimension anyway (commands, pre-existing portals) is sent back
world.afterEvents.playerDimensionChange.subscribe((ev) => {
  if (!closed() || ev.toDimension.id === OVERWORLD) return;
  const p = ev.player;
  const back = ev.fromDimension.id === OVERWORLD ? ev.fromLocation : world.getDefaultSpawnLocation();
  system.runTimeout(() => {
    try {
      p.teleport({ x: back.x + 0.5, y: Math.max(back.y, -60), z: back.z + 0.5 }, { dimension: world.getDimension("overworld"), checkForBlocks: false });
      warn(p);
      giveSupplyChest(p);
    } catch (e) {
      console.warn(`[RadioÚstí] dimension return: ${e}`);
    }
  }, 5);
});

// remove portal blocks that appear next to players in the overworld (e.g. from older worlds)
system.runInterval(() => {
  if (!closed()) return;
  for (const p of world.getAllPlayers()) {
    if (p.dimension.id !== OVERWORLD) continue;
    for (let dx = -3; dx <= 3; dx++)
      for (let dy = -2; dy <= 3; dy++)
        for (let dz = -3; dz <= 3; dz++) {
          const b = blockAt(p.dimension, { x: p.location.x + dx, y: p.location.y + dy, z: p.location.z + dz });
          if (b && (b.typeId === "minecraft:portal" || b.typeId === "minecraft:end_portal")) b.setType("minecraft:air");
        }
  }
}, 100);
