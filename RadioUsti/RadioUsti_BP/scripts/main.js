// RadioÚstí starter script.
// Claude: implement the complete add-on here and in the related pack files.
// Target Minecraft Bedrock 1.26.50. Prefer stable APIs and verify API compatibility.
// Do not claim runtime testing unless the pack has actually been launched in Minecraft.

import { world, system } from "@minecraft/server";

world.afterEvents.worldLoad.subscribe(() => {
  console.warn("[RadioÚstí] Starter script loaded. Gameplay systems have not been implemented yet.");
});
