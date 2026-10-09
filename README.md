# Unstable Arena

**Fight, dodge and survive on a tilting, fracturing stone platform inside a Roman-inspired coliseum.**

Current version: **0.8.0-overlook-combat**. This is a development build; Studio multiplayer and device playtesting remain necessary.

## Load this update

1. Stop the current Studio play session.
2. In the repository's VS Code window, use **Cmd+Shift+P → Git: Pull**.
3. Start Rojo for **default.project.json** and keep that server running.
4. In Studio, open the Rojo plugin, connect to the address/port shown by the server, and sync.
5. Press **Play**, not Run, to spawn a character.

Output should contain:

```text
[UnstableArena] 0.8.0-overlook-combat ready
```

If Rojo says it cannot connect, the live server is stopped or the plugin is using a different port. Git Pull updates VS Code files; Rojo copies those files into Studio. Both steps are necessary. In the repository terminal, `rojo serve default.project.json` is an alternative to the VS Code Start button when the CLI is on PATH.

Geometry is generated during Play. Keep local edits if Git reports a conflict; do not force-reset them.

## This update

- Meteors are 8.4 studs across (previous original model: 3.8) and fall 120 studs in 0.28 seconds after a 0.75-second telegraph. The warning follows the moving slab; impact detaches that exact slab.
- Impact tilt adds up to 8 degrees, with accumulated impact capped at 10 and total tilt capped at 26. A short faster response settles back into balance. Small platform tremors intensify after fractures.
- Slab thickness drops from 4.6 to 2.2 studs, with a thinner chipped underside. Stress accumulates at 2.5× the original rate.
- Pickups fill separated sectors between 32% and 65% of platform radius, at least 22 studs apart.
- Gladius and mace have unlimited uses during a round. They spend stamina and animate on misses. The mace is now a heavy overhead melee slam.
- Original multi-keyframe sword/mace clips animate the weapon grip and body. Both push arms override walking; combat also takes priority over slide arm poses.
- Detailed beveled blade, wrapped grip, pommel, chain and flanged mace geometry. Existing imported MeshPart templates are preserved.
- Everyone arrives in a raised enclosed overlook, with walk-on map/mode voting behind them. Eliminated players return there and retain POV spectating.
- Twelve additional upper arcade floors fade toward white/peach. A deeper layered chasm replaces the shallow flat void.
- Stamina drains during sprinting, dashes, slides and melee attacks, then regenerates. Adrenaline comes only from successful combat hits: 16 for landing, 6 for receiving.

See [implementation and verification notes](docs/impact-overlook-pass.md).

## Controls

| Action | Computer | Controller | Touch |
| --- | --- | --- | --- |
| Push | E; left-click with no ranged/melee weapon selected | R2 | PUSH |
| Grab/pull | Q | X | GRAB |
| Pick up | R | Y | Pickup prompt |
| Select item | 1 / 2 / 3 | LB / RB | Tap slot |
| Use item | F; left-click for sword/mace/bow | L2 | ITEM |
| Sprint | Hold Left Ctrl | L3 toggle | SPRINT toggle |
| Dash | X | B | DASH |
| Slide | C | R3 | SLIDE |
| Adrenaline rush | G | D-pad down | Tap ready bar |
| Mouse lock | Left Shift | — | — |
| Vote | Stand on a pad | Same | Same |
| Spectate / POV | Spectator buttons | HUD navigation | Spectator buttons |

Three item slots maximum. Taking a pickup with a full inventory replaces the selected slot; the prompt says “Take / swap.” Aim bows at the crosshair; face your opponent for melee attacks. Combat primarily causes knockback. Grab is a quick pull, not a sustained carry.

## Round and arena

Roman Coliseum is the only playable map. Map and mode votes each last 11 seconds, with a short transition. Stand on a pad for 0.6 seconds; your vote remains when you step away and changes when you select another pad.

Rounds last up to 175 seconds and end earlier when only one team remains. FFA, Duos and Squads fill toward eight competitors, with a maximum of nine NPCs. Team membership is assigned per round; there is no party system yet.

The platform is approximately 220 studs across and contains 84 independent fracture slabs. The main architectural shell is roughly 550 studs across, with distant seating beyond it. Dimensions are game scale, not a historical reconstruction.

Meteor showers and lions are mutually exclusive major events, with warnings and gaps between events. Weighted items, characters and hazards affect balance. Cracks warn before ordinary stress failures. NPCs can fall and make mistakes.

## Items

| Item | Uses | Effect |
| --- | ---: | --- |
| Gladius | Unlimited | Short-range slash, moderate knockback |
| Chain mace | Unlimited | Overhead close-range slam; strikes the ground on a miss |
| Shield | 2 | Each use blocks one hit within eight seconds |
| Bow | 3 | Aimed knockback arrows |
| Ram | 1 | Strong shove with recoil |
| Anchor | 1 | Five seconds of resistance, with added slab weight |
| Brace kit | 1 | Repairs 55% of slab durability; cannot restore fallen stone |
| Weight block | 1 | Eight seconds of extra local weight |

Adrenaline rewards landing and receiving combat hits; positioning and environmental damage do not charge it. At 100, activate a seven-second movement/push/resistance boost.

## Development checks

```sh
luau tests/Rules.spec.luau
luau tests/StoneLayout.spec.luau
python tests/run_engine_checks.py --luau /path/to/luau
rojo build default.project.json --output UnstableArena.rbxlx
```

The automated checks do not run Roblox physics or test final visual quality. Use Studio's two-client server test and mobile emulation before publishing.

## Current limits

Scores are session-only. There are no purchases, persistent progression, extra maps, production sound design or finished imported character/weapon assets. Third-party animation packs were researched but not installed without verifying the actual files and access. This build includes original procedural animation instead.

The scene still contains thousands of parts. Profile on target mobile hardware and consolidate scenery into meshes if needed. Client/server combat validation is implemented, but production anti-cheat and exploit testing are not complete.
