# Weapon Mesh Setup

The game now automatically prefers imported MeshPart templates for the **Sword** and **Mace**. Procedural geometry remains only as a safe fallback until the imported assets exist.

## 1. Import the meshes

In Roblox Studio:

1. Use **File > Import 3D** and import an `.fbx`, `.obj`, or `.gltf` sword/mace model.
2. Keep the geometry reasonably optimized. Use one MeshPart when possible, or a small multi-part Model when separate materials are needed.
3. Move the finished template into:

```
ReplicatedStorage
└── WeaponMeshes
    ├── Sword
    └── Mace
```

Rojo is configured with `$ignoreUnknownInstances: true` for this folder, so Studio-imported mesh assets are not deleted by live sync.

## 2. Required template structure

A single-mesh sword can simply be:

```
Sword (MeshPart)
```

Rename that MeshPart to **Handle** only if the Sword itself is stored as a Model.

Recommended multi-part structure:

```
Sword (Model)
├── Handle (MeshPart)       <-- REQUIRED grip/root part
├── Blade (MeshPart)
├── Guard (MeshPart)
└── Pommel (MeshPart)

Mace (Model)
├── Handle (MeshPart)       <-- REQUIRED grip/root part
├── Shaft (MeshPart)
├── Chain (MeshPart)
└── Head (MeshPart)
```

Only one BasePart inside each template should be named `Handle`.

The game automatically:
- disables collision/query/touch on weapon geometry,
- makes weapon parts massless,
- creates missing WeldConstraints from every mesh piece to the Handle,
- welds the Handle to the game's held-item grip,
- anchors the same template when it is rendered inside hotbar ViewportFrames.

## 3. Align the grip

Every Sword/Mace template supports a **CFrame attribute** named:

```
GripOffset
```

Select the Sword or Mace template itself and add a CFrame attribute called `GripOffset`.

Start with identity, then rotate/translate it until:
- the sword handle sits in the palm,
- the blade points away from the hand,
- the mace handle stays in the palm during the overhead windup,
- the weapon does not clip through the forearm during the combat stance.

Because the same template is used for held equipment, pickups, and hotbar previews, correct model orientation at the Handle is important.

## 4. Welding rules

If the weapon has multiple MeshParts:
- leave every part **unanchored** in the final template,
- use the Handle as the assembly root,
- weld all other parts to the Handle with WeldConstraints,
- do not create multiple competing Handles.

The game will create missing Handle welds automatically, so existing correct welds can remain.

## 5. If converting the custom inventory to Roblox Tools later

The current game intentionally uses its own three-slot inventory, so Sword/Mace templates are Models/MeshParts rather than Backpack Tools.

If you later convert one into a standard Roblox Tool, use:

```
SwordTool (Tool)
├── Handle (MeshPart)
├── Blade (MeshPart)
├── Guard (MeshPart)
└── ...
```

Then:
- set `Tool.RequiresHandle = true`,
- keep exactly one direct child BasePart named `Handle`,
- weld every additional MeshPart to Handle,
- keep every weapon part unanchored,
- use `Tool.Grip` to tune hand orientation.

For R15 attachment-driven setups, align the grip around the character's `RightGripAttachment`. If you already use a ToolGripEditor plugin, use it only to find the grip position/orientation, then copy the resulting CFrame into the Tool.Grip or this project's `GripOffset` attribute.

## 6. Animation alignment checklist

Test each imported mesh with:
- standing weapon stance,
- walking,
- sword slash 1,
- sword slash 2,
- mace overhead strike,
- push,
- dash,
- slide.

Adjust `GripOffset` rather than changing combat animation poses merely to compensate for a poorly oriented mesh.
