# 0.8.0: impacts, melee and the overlook

Built on remote commit 9581120, preserving the WeaponMeshes folder and imported-template support. The earlier impact/shift-lock changes are reconciled into the new systems rather than duplicated.

## Combat implementation

Sword and mace attacks start their animation before looking for a victim. The server checks the current character, round, active state and knockdown at contact time; targeting still requires range, facing and line of sight. Mace ground contact uses a downward arena ray and produces dust/stress even without an opponent. The homing projectile and its range ring are removed.

Motor6D WeaponGrip allows the held object to participate in the authored keyframes. Combat overrides shoulder/elbow/body transforms after Animator evaluation, with recovery blending back into locomotion. Both push shoulders are owned together. R6/R15 and AnimationConstraint joint discovery are supported in code; actual avatars still need Studio visual checks.

Sword/mace are permanent for the current round, not persistent unlocks. Bow ammunition and utility charges still deplete. Full inventories explicitly swap the selected slot on pickup. Imported meshes remain optional; the default geometry now includes beveled blade faces, rings, inlays, chain links and mace flanges.

Stamina is server-controlled: 100 maximum; sword 13, mace 24, dash 24, slide 18; moving sprint drains 15/second; recovery is 21/second after 0.85 seconds. Running out ends sprint. Fists remain usable. Combat adrenaline grants 16 on a landed hit and 6 to the victim; shield blocks, rescue pulls and environmental hits do not award it.

## Arena implementation

Stress is multiplied by 2.5; this increases the accumulation rate, not a promise that every round has precisely 2.5 times as many failures. The initial grace period is 10 seconds and ordinary failures retain a short visible crack warning. Meteors bypass durability and detach the exact warned slab.

Meteor warnings and visual endpoints use slab-relative positions so a tilting plate cannot drift out from under the warning. The visual fall takes 0.28 seconds after 0.75 seconds of warning. Impacts are cancelled if the event ends or target slab breaks first.

The plate adds small bounded tremors to the balance target, with stronger short decaying shakes on fractures/impacts. Total target tilt stays within 26 degrees. This uses server-owned constraints, not repeated character teleports.

Slabs have 2.2-stud bodies and a 0.55-stud chipped underside. Pickups stay in a central annulus with sector balancing and minimum separation. Spawn positions remain on separate solid slabs.

The raised observation box contains voting pads and the practice dummy. Its arrival camera faces down into the arena; collision walls/window keep spectators safe. The upper floors use simpler geometry, pale color grading and atmospheric haze. This is a game-inspired fantasy extension, not a historically accurate reconstruction. The chasm has descending dark strata, a longer central support and layered depth haze below the elimination plane.

## Research used

- [Roblox Motor6D documentation](https://create.roblox.com/docs/reference/engine/classes/Motor6D): Animator timing and procedural transforms.
- [Roblox AnimationConstraint documentation](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint): current joint animation compatibility.
- [Roblox Animation Editor](https://create.roblox.com/docs/animation/editor): animation/keyframe workflow.
- [Creator tool animation tutorial](https://devforum.roblox.com/t/how-to-animate-a-toolobject-with-a-dummy-in-the-animation-editor/232317/): rigging the held object with the character.
- [Creator Motor6D weapon tutorial](https://devforum.roblox.com/t/how-to-animate-your-tool-using-motor6d-fully-customizeable-idle-unsheathing-multiple-attacks-inspect-animations-and-sound-effects/3026706): reviewed search excerpts; full page blocked by verification.

The implementation uses original procedural clips and geometry. No third-party animation asset IDs or unverified model scripts were installed.

## Verification and remaining Studio checks

Standalone Luau compilation, pure rule/stone-layout tests, mocked server behavior checks and Rojo build are run for this update. The mock checks permanent melee, target-free attacks, delayed contacts, elimination cancellation, consumable bows, stamina exhaustion/regeneration, pickup spacing and exact-tile meteor impacts. The mock does not simulate physics, network latency, Animator or rendering.

Generated geometry was inspected with an offline renderer. It caught and corrected a blocked overlook camera. That preview does not reproduce Roblox glass, atmospheric haze, materials, UI or animation. The scene is still roughly 11,700 visible parts before live actors; mobile profiling and mesh consolidation remain necessary.

In Studio, verify:
1. Walking + E visibly extends both arms; sword and mace attacks play with no target.
2. Mace wind-up, ground contact and recovery read correctly on R6 and R15, including imported mesh grips.
3. Melee stays in the hotbar, bow ammunition depletes, and an exhausted player can still push.
4. Left Shift alone toggles mouse lock; Left Ctrl sprints; UI and touch controls stay readable.
5. Meteor warnings track tilted slabs; hits remove the target stone and produce recoverable tilt/shake.
6. The overlook arrival view shows the plate, voting is behind the spawn, and eliminated players return safely.
7. Two-client replication, mobile frame rate and actual match pacing are acceptable.

No live Roblox Studio playtest was available in this environment. Visual feel, physical tuning and multiplayer latency remain unverified.
