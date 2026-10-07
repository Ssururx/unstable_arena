# Arena quality pass · 0.6.0

## Scope

This pass improves the existing 0.5.0 systems. It is a playable development build, not a claim of finished production art or verified Roblox multiplayer performance.

- Three compact square hotbar slots. Empty slots contain no text, number, icon or count. Occupied slots use a lit 3D preview of the actual item, with a key hint and remaining uses. Selected occupied slots have a gold border.
- One reusable gallery: three boards, three pads. Map selection changes the same boards into FFA / Duos / Squads after a short transition. Only Coliseum is playable; unused map options are locked. Spawn faces the gallery.
- Original shared weapon models: pointed gladius, leather grip and bronze guard; shield with rim and boss; linked mace; bow; utility equipment. The same definitions build pickups, held models and inventory previews.
- Weapon-specific procedural wind-up, strike and recovery. Push, grab, sword, bow, mace, shield and slide poses are visible on other players as well as NPCs. NPC legs walk instead of staying frozen.
- Animation layers run around Animator evaluation (PreAnimation restores the prior base; PreSimulation applies the layer). Joint detection accepts Motor6D and AnimationConstraint. Normal player locomotion is retained.
- Sword hits are checked during the strike, after a short wind-up. Last-use equipment stays visible until the action finishes. Slot selection rejects malformed values and switching during a weapon action.
- Mace has a warning, a visible metal head with a tether, limited angular steering and terrain raycasts. Its acquisition ring is a thin dashed outline projected onto intact stone. It is not a large glowing floor disc.
- Shield use displays a held shield rather than a visible ForceField. Hits have brief crosshair confirmation.
- Dash and slide have brief server-controlled momentum rather than a single velocity write. Sprint clears on focus loss and opening the Roblox menu. Touch and controller movement controls are available.
- Platform response uses ballast and smoothing. A crowd on one side no longer multiplies early tilt into the maximum. Slope acceleration uses elapsed time instead of a hard-coded per-frame increment.
- Original stylized lion with rounded anatomy, mane, muzzle, articulated legs and moving tail. Safe-ground sampling replaces blindly setting forward velocity over holes. NPC gladiators react to nearby lion and meteor threats.
- Meteor callbacks belong to the event that scheduled them; major events are guarded against overlap. Warning radius matches the damage radius and vertical range is bounded.
- Distant seating uses fewer opaque pieces instead of layers of transparent geometry. Small cosmetic underside edge kinks are merged; playable slab collision stays unchanged.

## Animation research

Reviewed 7 October 2026. No third-party animation binaries or IDs were imported.

| Source | Finding | Decision |
| --- | --- | --- |
| [IceKing / aymanplaysz: Free to use animations kit](https://devforum.roblox.com/t/free-to-use-animations-kit/2025224) | Creator lists R15 locomotion, bow and melee/sword actions as shared resources. Search indexing exposes the description; direct retrieval encountered a verification wall. | Candidate for a later Studio review. Download contents, animation quality, rig compatibility and access were not verified, so it is not installed. |
| [Sword Animations R6, Creator Store](https://create.roblox.com/store/asset/18997471668/Sword-Animations-R6) | Public listing surfaced in research. Listing alone does not establish quality or compatibility with both avatar rigs. | Not imported. |
| [Roblox: Use animations](https://create.roblox.com/docs/animation/using) | Describes Animator:LoadAnimation and animation tracks. | Use this path if approved uploaded clips replace the original procedural layer later. |
| [Roblox: Improving Animation Asset Permissions](https://devforum.roblox.com/t/improving-animation-asset-permissions/3852101) and [sharing assets](https://devforum.roblox.com/t/sharing-animation-assets-with-connections-and-groups/3892540) | Animation access is managed through asset/experience permissions. A public-looking ID is not sufficient verification of playback access. | Do not add arbitrary IDs and assume they will play. |
| [Motor6D](https://create.roblox.com/docs/reference/engine/classes/Motor6D) / [AnimationConstraint](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint) | Joint transforms and their evaluation timing matter for procedural animation. | Detect both joint classes, restore each layer before Animator evaluation and apply offsets during PreSimulation. |

Original procedural animation and models need no paid assets or additional publishing step. They are stylized approximations, not motion capture. Final posing, hand placement, lion gait and avatar proportions must be reviewed in Studio.

## Verification

- Luau compiler for every source and test module.
- Engine-independent tests cover malformed slot indices, crowd balance, smoothing at 30/144 Hz, late-round stress, team rules and polygon validity at both old and current platform sizes.
- Rojo build checks the DataModel mapping and module packaging.
- A local geometry stand-in constructs the actual scene, verifies finite dimensions/transforms and checks three-board voting phases and spawn orientation. Offline renders inspect geometry only; they do not reproduce Roblox materials, UI rendering, animation, replication or physics.

## Studio acceptance pass

1. Stop Play, pull GitHub main, serve default.project.json, connect Rojo, then Play. Check the 0.6.0 startup line.
2. Spawn facing the three boards. Vote on Coliseum, then verify the exact same three boards show modes.
3. Pick up three items. Confirm blank empty squares, previews, 1–3 selection, consumption, final-use follow-through and respawn cleanup.
4. Test both R6 and R15, including an avatar using AnimationConstraints. Check sword guard, bow draw, shield placement, slide crouch, remote-player animations and NPC gait.
5. Start Server with two clients: confirm knockback, sword strike timing, dash recovery and mace misses around terrain. Watch for delayed or stuck network ownership.
6. Check touch emulation and a controller: pickup, select, item use, sprint, dash, slide and adrenaline.
7. Verify meteor circles are readable on tilted ground, impacts follow their warning and lions avoid holes without hovering. Major events must not overlap.
8. Run a full 175-second round, reset during a warning, then play again. No prior-round delayed effects should affect the next match.
9. Profile on the lowest target mobile device. The scene still uses thousands of procedural parts; further mesh consolidation may be needed. No FPS claim has been made.

Persistent progression, purchases, production audio, authored imported character animation, additional maps and final mesh art remain separate work.
