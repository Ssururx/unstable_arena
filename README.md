# Unstable Arena

**Fight, dodge and survive on a tilting, fracturing stone platform inside a Roman-inspired coliseum.**

Current version: **0.6.0-arena-polish**. This is a development build; Studio multiplayer and device playtesting remain necessary.

## Load this update

1. Stop the current Studio play session.
2. In the repository's VS Code window, use **Cmd+Shift+P → Git: Pull**.
3. Start Rojo for **default.project.json** and keep that server running.
4. In Studio, open the Rojo plugin, connect to the address/port shown by the server, and sync.
5. Press **Play**, not Run, to spawn a character.

Output should contain:

```text
[UnstableArena] 0.6.0-arena-polish ready
```

If Rojo says it cannot connect, the live server is stopped or the plugin is using a different port. Git Pull updates VS Code files; Rojo copies those files into Studio. Both steps are necessary. In the repository terminal, `rojo serve default.project.json` is an alternative to the VS Code Start button when the CLI is on PATH.

Geometry is generated during Play. Keep local edits if Git reports a conflict; do not force-reset them.

## This update

- Three small square inventory slots. Empty means completely blank; occupied slots show the actual weapon model, uses and selection border.
- Exactly three voting boards and three pads, reused for map and mode selection. Spawn faces them.
- Weapon-specific combat motions, visible on players and NPCs; animated slides and NPC walking.
- More detailed gladius, shield, chain mace, bow and utility models, shared across ground pickups, hands and inventory.
- Mace warning, visible tethered projectile, limited tracking and terrain collision.
- Gradual platform balance with less early sensitivity; frame-rate-independent slope acceleration.
- Sustained dash/slide momentum, touch/controller movement controls and clearer hit feedback.
- Rounded, articulated lion models and NPC hazard avoidance.
- Less redundant scenery and underside geometry.

The [quality notes](docs/quality-pass.md) record animation research, implementation details, limitations and the Studio acceptance pass.

## Controls

| Action | Computer | Controller | Touch |
| --- | --- | --- | --- |
| Push | E / left-click | R2 | PUSH |
| Grab/pull | Q | X | GRAB |
| Pick up | R | Y | Pickup prompt |
| Select item | 1 / 2 / 3 | LB / RB | Tap slot |
| Use item | F | L2 | ITEM |
| Sprint | Hold Left Shift | L3 toggle | SPRINT toggle |
| Dash | X | B | DASH |
| Slide | C | R3 | SLIDE |
| Adrenaline rush | G | D-pad down | Tap ready bar |
| Mouse lock | Right Shift | — | — |
| Vote | Stand on a pad | Same | Same |
| Spectate / POV | Spectator buttons | HUD navigation | Spectator buttons |

Three item slots maximum. Aim bows at the crosshair; the mace acquires a nearby visible enemy in front of you. Combat primarily causes knockback. Grab is a quick pull, not a sustained carry.

## Round and arena

Roman Coliseum is the only playable map. Map and mode votes each last 11 seconds, with a short transition. Stand on a pad for 0.6 seconds; your vote remains when you step away and changes when you select another pad.

Rounds last up to 175 seconds and end earlier when only one team remains. FFA, Duos and Squads fill toward eight competitors, with a maximum of nine NPCs. Team membership is assigned per round; there is no party system yet.

The platform is approximately 220 studs across and contains 84 independent fracture slabs. The main architectural shell is roughly 550 studs across, with distant seating beyond it. Dimensions are game scale, not a historical reconstruction.

Meteor showers and lions are mutually exclusive major events, with warnings and gaps between events. Weighted items, characters and hazards affect balance. Cracks warn before ordinary stress failures. NPCs can fall and make mistakes.

## Items

| Item | Uses | Effect |
| --- | ---: | --- |
| Gladius | 5 | Short-range slash, moderate knockback |
| Chain mace | 3 | Warned, dodgeable pursuit projectile |
| Shield | 2 | Each use blocks one hit within eight seconds |
| Bow | 3 | Aimed knockback arrows |
| Ram | 1 | Strong shove with recoil |
| Anchor | 1 | Five seconds of resistance, with added slab weight |
| Brace kit | 1 | Repairs 55% of slab durability; cannot restore fallen stone |
| Weight block | 1 | Eight seconds of extra local weight |

Adrenaline rewards attacks and risky positioning. At 100, activate a seven-second movement/push/resistance boost.

## Development checks

```sh
luau tests/Rules.spec.luau
luau tests/StoneLayout.spec.luau
rojo build default.project.json --output UnstableArena.rbxlx
```

The automated checks do not run Roblox physics or test final visual quality. Use Studio's two-client server test and mobile emulation before publishing.

## Current limits

Scores are session-only. There are no purchases, persistent progression, extra maps, production sound design or finished imported character/weapon assets. Third-party animation packs were researched but not installed without verifying the actual files and access. This build includes original procedural animation instead.

The scene still contains thousands of parts. Profile on target mobile hardware and consolidate scenery into meshes if needed. Client/server combat validation is implemented, but production anti-cheat and exploit testing are not complete.
