# Coliseum design and engineering notes

Reviewed October 6, 2026. This pass replaces the prototype's dominant square-grid shape and menu-first lobby with a coherent, single-environment arena.

## Architecture and composition

The Colosseum references show that its identity comes from the broad oval, layered cavea/seating, repeated open arcades and strong horizontal divisions. The reference structure has multiple exterior stories, with open arcades on the lower three. Our build uses a near-circular footprint and simplified orders, scaled for Roblox movement. It does not claim exact Roman dimensions or decorative accuracy.

Sources:

- [Parco archeologico del Colosseo: the Colosseum](https://colosseo.it/en/area/the-colosseum/) — official archaeological site and architectural context.
- [Ancient Rome Live: Colosseum](https://ancientromelive.org/colosseum-flavian-amphitheatre/) — architectural description, plan, exterior orders and visual references.
- [Parco archeologico del Colosseo: capitals](https://colosseo.it/en/opere/capitals/) — surviving material and ornament references.

Applied choices:

- Repeated real openings, engaged columns and cornices define the silhouette.
- Three continuous spectator concourses connect through seating/stair bands.
- Warm limestone carries most of the image; bronze and faded red are restrained accents.
- A broad entrance courtyard provides a clear view into the bowl.
- The fighting surface remains the center of attention. Its radius is about 52 studs, approximately twice the old actual slab-grid width.
- Stone is thick, varied and fractured; shape variation is coordinated along shared boundaries so “natural-looking” does not create arbitrary avatar-sized gaps.

## Lighting

Roblox's guidance distinguishes Realistic lighting, environmental diffuse/specular response, atmosphere and post-processing. These tools need a restrained combination: excessive bloom or haze would hide opponent silhouettes and fracture warnings.

- [Global lighting](https://create.roblox.com/docs/environment/lighting)
- [Outdoor lighting tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments)
- [Atmosphere](https://create.roblox.com/docs/reference/engine/classes/Atmosphere)
- [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects)

Applied choices: Realistic lighting in the Rojo project, late-afternoon sunlight, moderate ambient fill, subtle warm grading and low bloom. Braziers use few short-range lights with shadows disabled. Smoke/dust replaces neon spheres. A plain offline geometry render cannot validate the final Roblox look.

## Geometry and performance

- [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- [Instance streaming](https://create.roblox.com/docs/workspace/streaming)
- [Streaming techniques](https://create.roblox.com/docs/workspace/streaming/techniques)
- [WedgePart](https://create.roblox.com/docs/reference/engine/classes/WedgePart)
- [EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh)

Applied choices:

- Architecture is anchored and built once per server; round resets rebuild the platform, not the amphitheater.
- Keep gameplay support and visible decoration separate: decorative support drums cannot catch falling competitors or collide with the rocking assembly.
- Static seating uses fewer angular segments than the outer silhouette. Disable touch events on noninteractive geometry and shadows on tiny fracture strips.
- The platform uses ordinary wedge prisms rather than requiring uploaded mesh assets or adding a runtime EditableMesh dependency to setup.
- Broken stone and temporary effects have bounded lifetimes; arrows use throttled visual updates.
- Bot decisions run at about 4.5 Hz, not every rendered frame. Cosmetic walking/shove poses run locally.

Tradeoff: procedural Parts make this easy to pull into Studio, but they are not the final lowest-draw-call asset pipeline. The environment contains thousands of parts and the platform hundreds of collision wedges. Do not claim mobile-ready performance from a successful compiler or desktop geometry render. Measure in Studio/device testing; if needed, replace repeated static modules with authored MeshParts before adding more decoration.

Streaming documentation was reviewed, but this pass does not silently change the place's streaming settings. If streaming is enabled, specifically verify remote spectator targets and NPC animation registration under stream-in/out before publishing.

## NPCs and combat

- [Humanoid movement](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
- [Pathfinding](https://create.roblox.com/docs/characters/pathfinding)
- [Network ownership](https://create.roblox.com/docs/physics/network-ownership)
- [Collisions](https://create.roblox.com/docs/workspace/collisions)

Applied choices:

- Treat humans and bots as round actors so team validation, shield use, knockback, elimination and winner logic agree.
- Keep NPC assemblies server-owned, including after the countdown unanchors them.
- The arena moves and pieces vanish. Use short-range steering against current intact surfaces instead of a static path through old ground positions.
- Sample nearby footing before moving; approach the nearest opponent; use a modest, imperfect shove cadence. Bots are intentionally basic and may misjudge recovery.
- Never give bots a direct “kill player” ability. They call the same shove/grab/item services.
- Do not confuse server-validated attacks with a comprehensive character-movement anti-cheat.

## Lobby interaction

The request is implemented as sequential walk-on floor selections. The map pad opens first, the arena rebuilds, then rectangular mode pads activate. Choices are read from server-observed character positions with a dwell threshold; the old client vote remote no longer accepts selection requests.

The default is Coliseum/FFA if nobody votes. There is one playable map, rather than inactive biome choices masquerading as finished content. Players retain control of movement and camera throughout the selection phase.

## Verification boundary

The repository includes deterministic pure-Luau tests for geometry and game rules. A separate geometry stand-in was used to inspect actual generated part placements and identify obstructions, but it is not Roblox Studio. Real physics behavior, humanoid grounding, camera interaction, replication, mobile frame time and the final material/light appearance still require the README's Studio acceptance checks.
