# Unstable Arena — 0.2 playtest

**Push other players off a tilting, cracking slab arena. Stay on until the end.**

Expanded Roblox/Luau playtest, not a launch-certified game. All geometry is generated from Parts; no purchased assets or manual models are required. Changes appear when you run Play, not in the stopped editor.

## Get this update into Studio

1. Stop the current Studio play session.
2. In VS Code, open this repository. Press **Cmd+Shift+P**, choose **Git: Pull**.
3. Keep the Rojo server running for `default.project.json`. Connect the Studio Rojo plugin and accept the sync if prompted.
4. Press **Play** again. Output should say `[UnstableArena] 0.2.0-playtest ready`.

If Pull reports a conflict, keep your local work and resolve it before continuing; do not reset or force-pull. Edit code in VS Code, not the Rojo-managed Studio script copies.

The boot script replaces the stock Workspace `Baseplate` and `SpawnLocation` during Play and constructs `UnstableArenaWorld`. Other user-authored scenery is preserved.

## Implemented

- Faster, server-owned plate response: responsiveness 30, maximum angular speed 3.8 rad/s, maximum tilt 26 degrees. Player positions and weight items drive the tilt; map-specific rocking adds pressure.
- 21 slightly irregular slabs with randomized durability, three readable crack stages, a minimum final warning, neighbor stress, and accelerating late-round collapse. Slab timing is not an identical fixed timer.
- **Roman Coliseum:** stone slabs, banners, amphitheater shell, 85-second limit.
- **Amazon Rapids:** wooden raft slabs, water/jungle scenery, stronger rocking, more bows, 65-second limit. This is a stylized arena theme, not a historical recreation or simulated river.
- Persistent lobby/spectator walkway, practice targets that reset, spaced round spawns facing inward.
- Map and FFA/Duos/Squads voting. Ties choose randomly. Teams are shuffled each round, shown by outlines, and cannot push/shoot their teammates. Grab can help a teammate. Teams may be uneven when player counts do not divide evenly. Modes fall back to FFA if there would be only one team.
- Up to 16 competitors. Late joiners wait in the lobby. One-player servers automatically run solo practice without wins or coins.
- Server-validated short-range shoves, quick grab/pull, cooldowns, line of sight, hit effects, knockout credit, brief server ownership of knocked characters.
- Six one-slot pickups; validated proximity collection and server-simulated bow hit tests.
- Shift-key mouse lock, mouse/keyboard, gamepad buttons, touch action buttons, adaptive HUD, item hints, round timer, voting and notifications.
- Walk-around spectator stands plus third-person follow and approximate first-person head-camera view. The latter does not reproduce another player's exact mouse/camera input.
- Session-only wins, KOs and coins. Winner/team: 30 coins; participation: 5; credited knockout: 5. Solo practice awards none.

## Controls

| Action | Computer | Gamepad | Touch |
| --- | --- | --- | --- |
| Push | E or left click | R2 | PUSH |
| Grab/pull | Q | X | GRAB |
| Use held item | F | L2 | ITEM |
| Take pickup | R | Y | Pickup prompt |
| Mouse lock | Left or right Shift | — | — |
| Spectate / change POV | HUD buttons | HUD navigation | HUD buttons |

Face someone within nine studs to shove. Grabs reach seven studs and are a quick tug, not a sustained carry mechanic. Bows fire toward the center crosshair. Shift lock rotates your character toward the camera, and releases for menus/chat/voting/spectating. Default Roblox mouse lock is disabled so it cannot double-toggle with this custom control.

## Pickups

| Pickup | Effect | Tradeoff |
| --- | --- | --- |
| Shield | Blocks one knockback hit; expires after 8 seconds | Does not prevent falling |
| Anchor | Reduces incoming knockback for 5 seconds | Triples effective weight/stress contribution |
| Ram | Stronger forward shove | Recoil; a miss still consumes it |
| Brace Kit | Repairs 65% of the current slab's maximum durability | Cannot restore a fallen slab |
| Weight Block | Adds three units of weight to your slab for 8 seconds | Can break your own footing |
| Knockback Bow | Three server-traced arrows with light drop | Aiming required; impacts can damage slabs |

Pickups appear on relatively safe intact slabs, up to five at once. Players carry one item and cannot replace it until used. No item is purchased for Robux.

## Architecture and tuning

- `src/shared/Config.luau`: physics, timers, maps, item metadata.
- `src/shared/Rules.luau`: engine-independent team/end-state/stress rules.
- `src/server/ArenaService.luau`: generated world, platform, fracture simulation, practice dummies.
- `src/server/PushService.luau`: target validation, shove/pull, ownership and knockout attribution.
- `src/server/ItemService.luau`: pickups, consumables, projectile simulation.
- `src/server/RoundService.luau`: lifecycle, votes, teams, elimination, session rewards.
- `src/server/init.server.luau`: initialization and rate-limited action router.
- `src/client/init.client.luau`: input, custom mouse lock, UI, spectator cameras, local visual effects.

The server decides targets, ranges, cooldowns, item use and winners. Client aim is checked for finite values and normalized. This is basic action validation, **not a complete movement/flight anti-cheat**. Player characters still use Roblox's usual client movement model.

To adjust plate speed, start with `Arena.Response` and `Arena.AngularSpeed`; tilt leverage is `Arena.TiltPerStud`. Change one setting at a time during a two-client test. Higher is not automatically more playable.

## Validation

Checked outside Studio with Luau 0.741 and Rojo 7.7.1:

- All source/test files compile.
- `luau tests/Rules.spec.luau`: 74 assertions for team grouping, ending conditions, solo practice, numeric validation, tilt caps and slab stress.
- `luau-analyze src/shared/Rules.luau tests/Rules.spec.luau`: engine-independent type analysis.
- `rojo build default.project.json --output UnstableArena.rbxlx`: valid Rojo place build.

These checks do **not** execute Roblox physics, camera behavior or network replication. Full Roblox type diagnostics and runtime testing must be run in Studio; the standalone analyzer does not include Roblox globals.

### Required Studio playtest before publishing

1. Run solo. Confirm the lobby, practice dummies and round UI appear without red Output errors. E/click should visibly move a nearby dummy. Shift should center the mouse and allow camera-facing movement; chat and Escape should release it.
2. Walk toward different plate edges. Check that the tilt follows weight quickly without violent flinging. Observe all three crack stages and warning before a slab falls. Jumping/slab gaps should not feel arbitrary.
3. Start a local server with **two clients**. Shove, miss, grab, fall and reset. Check that one elimination produces one result, KO credit does not double-award, and survivors return to the lobby for the next vote.
4. Test both map votes. Use at least four clients for Duos and eight for two full Squads. Confirm teammates cannot shove/shoot each other, grabs can pull allies, and last surviving team gets one win per roster member.
5. Test all six pickups. Shield must disappear after the first blocked hit or 8 seconds. Anchor must increase slab stress. Repair must reset damage warnings when enough damage is healed. Weight must expire. Bow must stop at walls and consume exactly three uses.
6. Eliminate one client, switch between stands/third/first POV, then eliminate its spectated target. Confirm the next round restores that client's own camera and movement.
7. Join late, leave during countdown, reset during countdown, leave as last survivor, and run three consecutive rounds. Check for frozen roots, missing lobby floors, duplicated awards and leaked pickups.
8. Test touch/device emulation and an actual gamepad. Check portrait/small landscape screens, pickup prompts, action placement and camera controls. Run network simulation and mobile performance tests before release.

## Deliberately not shipped yet

- Persistent DataStore progression/inventory, cosmetic shop and purchase receipts. Coins currently reset when leaving; there are no paid products.
- Party-preserving matchmaking or separate mode queues. Duos/Squads are per-round server team sizes, not cross-server matchmaking.
- Final meshes, character animations, music/SFX, polished bow/held-item models, thumbnails and onboarding art.
- Proven exploit resistance, performance budgets and balance at 16 players.

Do not advertise this as a finished monetized release until those systems and the Studio checklist are complete. Publish/save the place manually from Studio after testing; a GitHub commit alone does not publish a Roblox experience.
