// Post-apocalyptic environment of RadioÚstí.
//  * Sky: permanently greenish (client biomes, RP). In Vibrant Visuals the RadioÚstí atmosphere also
//    turns the sky red at dusk/dawn and blood red at night.
//  * Fog presets per time of day (green day, red dusk/dawn, deep red night) pushed with /fog, so the
//    colour shift is visible in classic graphics too.
//  * Random smog events and radioactive rain (dose for players under the open sky, slow contamination).
// Config: /scriptevent radiousti:config environment on|off · rainradiation on|off · smog now
import { world, system, BlockPermutation } from "@minecraft/server";
import { NS } from "../lib/util.js";
import { Config } from "../lib/store.js";

const STACK = "radiousti_env";
const current = new Map(); // player.id -> fog id
let smogUntil = 0;

export function isRaining() {
  return world.getDynamicProperty("ru:raining") === true;
}

world.afterEvents.weatherChange.subscribe((ev) => {
  if (ev.dimension !== "minecraft:overworld" && ev.dimension !== "overworld") return;
  world.setDynamicProperty("ru:raining", ev.newWeather !== "Clear");
});

export function phase(t = world.getTimeOfDay()) {
  if (t >= 11500 && t < 13500) return "dusk";
  if (t >= 13500 && t < 22500) return "night";
  if (t >= 22500) return "dawn";
  return "day";
}

export function startSmog(minutes = 3) {
  smogUntil = system.currentTick + minutes * 60 * 20;
  for (const p of world.getAllPlayers()) p.onScreenDisplay.setActionBar("§7Nad RadioÚstí se valí hustý smog…");
}

export function isSmog() {
  return system.currentTick < smogUntil;
}

function fogFor(player) {
  if (player.dimension.id !== "minecraft:overworld") return undefined;
  if (isSmog()) return "smog";
  if (isRaining()) return "rain";
  return phase();
}

function applyFog(player, id) {
  if (current.get(player.id) === id) return;
  try {
    player.runCommand(`fog @s remove ${STACK}`);
    if (id) player.runCommand(`fog @s push ${NS}:fog_${id} ${STACK}`);
    current.set(player.id, id);
  } catch {
    /* commands unavailable (e.g. player leaving) */
  }
}

/** Under the open sky (no block above the player's head)? */
export function underSky(player) {
  try {
    const top = player.dimension.getTopmostBlock({ x: player.location.x, z: player.location.z });
    return !top || top.location.y < player.location.y + 1;
  } catch {
    return false;
  }
}

function rainContamination(player) {
  if (Math.random() > 0.1) return;
  const x = Math.floor(player.location.x + (Math.random() * 40 - 20));
  const z = Math.floor(player.location.z + (Math.random() * 40 - 20));
  try {
    const top = player.dimension.getTopmostBlock({ x, z });
    if (top?.typeId === "minecraft:grass_block") top.setPermutation(BlockPermutation.resolve(`${NS}:contaminated_grass`));
  } catch {
    /* unloaded */
  }
}

function tick() {
  const cfg = Config.get();
  const players = world.getAllPlayers();
  if (cfg.environment === false) {
    for (const p of players) applyFog(p, undefined);
    return;
  }
  if (!isSmog() && !isRaining() && Math.random() < 1 / 240) startSmog(2 + Math.floor(Math.random() * 4));
  for (const p of players) {
    applyFog(p, fogFor(p));
    if (isRaining() && cfg.rainRadiation !== false && p.dimension.id === "minecraft:overworld") rainContamination(p);
  }
}

world.afterEvents.playerSpawn.subscribe((ev) => current.delete(ev.player.id));
world.afterEvents.playerLeave.subscribe((ev) => current.delete(ev.playerId));
system.runInterval(() => {
  try {
    tick();
  } catch (e) {
    console.warn(`[RadioÚstí] environment: ${e}`);
  }
}, 100);
