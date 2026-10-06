# Unstable Arena · Coliseum pass

**Push opponents off a tilting, fracturing stone platform inside a Roman-inspired amphitheater.**

Version **0.3.0-coliseum** focuses on one environment. Amazon is removed from the playable map list for now.

## Load the update

1. Stop the current Studio play session.
2. In the repository's VS Code window, press **Cmd+Shift+P → Git: Pull**.
3. Keep Rojo running for `default.project.json`, and connect/sync the Studio plugin.
4. Press **Play**. Output should include `[UnstableArena] 0.3.0-coliseum ready`.

Geometry is generated during Play. It will not appear in the stopped editor. The script removes the stock `Baseplate` and `SpawnLocation` during Play; it preserves other user-authored scenery. Keep local edits if Git reports a conflict; do not force-reset them.

## What changed

- **A much larger amphitheater:** approximately 330 studs across, near-circular plan, three outer arcade stories, three walkable concourses, radial stairs, stepped seating, banners, statues, bronze trim and braziers. This is game-scale architectural inspiration, not a measured historical reconstruction.
- **A platform approximately twice the old width:** about 100 studs across versus the old roughly 50-stud slab grid. Width, rather than area, is doubled.
- **38 fitted stone chunks:** irregular fracture outlines, small kinks on shared edges, narrow fissures, varied stone tones, tapered rocky undersides and branching damage cracks. They are not square tiles. All collision comes from ordinary Roblox Parts/WedgeParts; no mesh upload or EditableMesh permission is required.
- **Coliseum-only art direction:** limestone and bronze, subdued red banners, warm afternoon shadows, subtle atmosphere, quiet color correction and dust impacts.
- **Gladiator NPCs:** a solo FFA round fills with five NPC opponents. They pursue nearby enemies, shove/grab, sample the remaining ground, attempt simple recovery jumps and use pickups. Teams and elimination include NPCs. NPCs use server-owned physics and the same combat validation as humans.
- **Physical lobby selection:** the map floor pad opens first; after map selection/rebuild, three rectangular mode pads open. Stand on a pad for 0.6 seconds to select it. No voting modal, welcome popup or repeated miss messages.
- **Reduced HUD:** compact status/timer, small keyboard help, touch action buttons, held-item card only when carrying something, and spectator controls when eliminated.
- **Physical pickup models:** shield, bow, anchor, ram, brace and stone weight, replacing neon cubes. Existing item behavior is retained.

## The lobby flow

The courtyard has one map pad: **Roman Coliseum**. Stand on it during the 9-second map phase. When the map phase ends, the platform rebuilds and the **FFA / Duos / Squads** floor rectangles become active for 10 seconds. Walk onto one to select it. The count on each pad updates for everyone.

Selections are per-player votes retained after stepping away; standing on a different pad changes your vote. No selection defaults to Coliseum and FFA. Map and mode stages are sequential, not simultaneous. The UI never takes camera/movement control for voting.

There is intentionally only one playable map in this pass. Selecting it rebuilds the stone layout; it does not load a second biome.

## Controls

| Action | Computer | Gamepad | Touch |
| --- | --- | --- | --- |
| Push | E / left-click | R2 | PUSH |
| Grab/pull | Q | X | GRAB |
| Use item | F | L2 | ITEM |
| Collect pickup | R | Y | Pickup prompt |
| Mouse lock | Either Shift key | — | — |
| Choose map or mode | Walk onto an active floor pad | Same | Same |
| Spectate / change POV | Spectator buttons | HUD navigation | Spectator buttons |

Push within nine studs, facing the target. Grab is a quick pull, not a sustained carry/throw. Aim bows at the center crosshair. Shift lock releases for chat and the Roblox menu. First-person spectating follows the target's head; it is not their exact replicated camera.

## NPC behavior and teams

FFA/Duos fill toward six competitors; Squads fills toward eight so a solo player can play with two full squads. There are at most seven NPCs and 16 human competitors. Bots disappear as human player counts fill the target, and never respawn into a round after elimination.

NPCs have slower push decisions than a human and can make mistakes. They use local raycast steering because the platform moves and loses pieces; they do not use a fixed baked path through the arena. They are not advanced strategic opponents. Reset, leave and respawn behavior still needs Studio network testing.

Friendly shoves/arrows are disabled; grabs can pull allies. Teammate outlines appear only in team modes. Session wins/KOs/coins include bot matches. Scores are temporary and there are no purchases or persistent progression.

## Pickups

| Pickup | Effect | Limitation |
| --- | --- | --- |
| Shield | Blocks one knockback hit within 8 seconds | Does not prevent falling |
| Anchor | Reduces knockback for 5 seconds | Adds slab stress and weight |
| Ram | Strong shove | Recoil; misses consume it |
| Brace | Repairs 65% of a slab's durability | Cannot restore fallen stone |
| Weight | Loads a slab for 8 seconds | Can break your own footing |
| Bow | Three knockback arrows with drop | Requires aim; impacts stress stone |

One held item at a time. Pickup prompts are distance/state/visibility checked on the server.

## Main files

| File | Purpose |
| --- | --- |
| `src/server/Coliseum.luau` | Architecture, lighting, lobby floor pads |
| `src/shared/StoneLayout.luau` | Deterministic irregular stone outlines |
| `src/server/Geometry.luau` | Ring segments and triangle-prism construction |
| `src/server/ArenaService.luau` | Slab assembly, tilt, stress, fracture and spawn selection |
| `src/server/BotService.luau` | Gladiator rigs and basic movement/combat decisions |
| `src/server/RoundService.luau` | Sequential pad voting, rosters, teams and results |
| `src/server/PushService.luau` | Combat validation and brief knockback ownership |
| `src/server/ItemService.luau` / `ItemVisuals.luau` | Item behavior and small physical models |
| `src/client/init.client.luau` | HUD, Shift lock, local NPC animation, effects and spectators |
| `src/shared/Config.luau` | Timers, balance, size and NPC tuning |

## Checks performed outside Studio

- All Luau source/test files compile.
- 74 existing rule assertions pass.
- 11,386 geometry/NPC-fill assertions pass over five layout seeds, covering valid stone interiors, triangulation area, bounds, playable minimum size and NPC counts.
- Engine-independent modules/tests pass standalone Luau type analysis.
- Rojo 7.7.1 builds the place successfully.
- A geometry-only mock constructs the world, checks pad bounds/spawns/finite part sizes, creates NPC rigs/item models, and exports geometry for visual inspection from the courtyard, platform and exterior.

The mock/render does **not** reproduce Roblox materials, SurfaceGui text, character physics or multiplayer replication. It found and helped correct obstructing lobby signs and a visible gap beneath the stands. It is not a substitute for a Studio playtest. Part-based construction also needs a mobile performance check before release.

## Studio acceptance checks

1. Start Play and inspect Output. Look around before selecting: no voting window should cover the scene.
2. Walk onto Coliseum, wait for mode pads to activate, then stand on FFA. Votes should increment once and only in the matching phase.
3. Start solo: five named gladiators should join you, approach opponents and fight. Push one, get pushed, use an item, and check that eliminated bots stay out.
4. Walk up the seating stairs to each concourse. Check transitions, lobby entrances, guards and camera clipping.
5. Stand on different platform edges, jump across fissures, repair damaged stone and watch it break. The support drum must not catch falling players or block the tilt.
6. Choose Duos, then Squads. Confirm friendly-fire rules and that a surviving NPC team can win a round. Check a human's win when their surviving teammate is an NPC.
7. Spectate a human and an NPC in both POVs. Eliminate the watched target and verify the camera cycles safely and returns next round.
8. Run at least two Studio clients through three rounds, including reset/join/leave during countdown and combat.
9. Use device emulation plus a real mobile device. Check lighting readability, frame time, NPC costs, touch controls and network simulation. The desktop geometry preview cannot certify this.

Research references and the decisions they informed are in [docs/coliseum-development-notes.md](docs/coliseum-development-notes.md).
