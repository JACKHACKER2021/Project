# Claude task — RadioÚstí complete implementation

You are working INSIDE this starter project. Implement the full RadioÚstí Minecraft Bedrock add-on described by the user in the accompanying specification. Do not return only advice, pseudocode, or isolated snippets: edit and create the actual project files in this directory, then package the finished `.mcaddon`.

## Project rules
- Keep `RadioUsti_BP` and `RadioUsti_RP` as the two pack roots.
- Keep their manifest UUID dependency aligned. If you change UUIDs, update all references.
- Target Bedrock 1.26.50; prefer stable APIs. Verify each API call against the version you use.
- Create a proper `pack_icon.png` for both packs.
- Add the complete custom geometry, textures, blocks, items, recipes, scripts, sound definitions, guidebook and README.
- Implement the requested RadioÚstí content: directional pipe families and valves; cables; multiblock generators; fictional nuclear plant; Windows Longhorn-inspired interactive PC and server; reusable System Analyzer; uranium and contaminated terrain; realistic pickaxe; blood/flesh/jars/flasks/oils; laboratory tables; furniture and hospital equipment; switchable lights; alarms; true two-block doors; retro Czechoslovak pixel-art blocks; documents and 2072 posters; soul materials; medieval fortress and zombie-apocalypse atmosphere.
- The user wants the complete project built in one continuous implementation, not a sequence of separate partial deliverables. You may work internally in a sensible order, but finish and package the full result before reporting completion.
- Do not replace requested functionality with decorative placeholders without explicitly recording the limitation.
- Validate JSON, geometry, manifest UUIDs/dependencies, script syntax, referenced textures and archive integrity.
- Distinguish static validation from actual in-game testing. Never claim Bedrock runtime testing unless it was performed.
- Preserve project files and provide a changelog, installation steps, item/block catalogue, recipes and an in-game construction guide matching the actual implementation.

## Deliverables
1. Completed project folders.
2. Final installable `RadioUsti.mcaddon`.
3. A concise test report and known-limitations list.
4. A feature checklist marked implemented / statically validated / tested in Minecraft / incomplete.

The detailed design specification supplied by the user is authoritative. When requirements conflict with stable Bedrock API limitations, choose the most reliable supported implementation and document the trade-off.
