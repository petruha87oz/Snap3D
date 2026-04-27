# 🧲 Snap3D — 3D Magnetic Object Snapping for Godot 4

A plugin for snapping (magnetically attracting) 3D objects in Godot 4.x without
any dependency on keyboard shortcuts or mouse buttons. Fully functional in the
Godot mobile editor on Android.

---

## 📦 Installation

1. Copy the `addons/snap3d/` folder into the root of your Godot project.
2. Open **Project → Project Settings → Plugins**.
3. Find `Snap3D` and click **Enable**.
4. The **🧲 Snap3D** dock will appear in the right editor panel.

---

## 🚀 How to Use

### Step 1 — Select
Select one or more `Node3D`-compatible objects in the scene
(by tapping them in the 3D viewport or the scene tree).
The dock will show what is selected.

### Step 2 — Configure

| Parameter | Description |
|---|---|
| **Mode** | Snap point type: Vertex / Edge / Surface / Origin |
| **Target** | What counts as a target: All objects / CSG only / MeshInstance3D only |
| **Radius (m)** | Maximum search distance from the selected object |
| **Align to surface normal** | Rotate the object to match the snap surface normal |
| **Show preview** | Display target coordinates in the panel before moving |

### Step 3 — Act

| Button | Action |
|---|---|
| 🧲 **Snap to Nearest Point** | Moves the selected object so its closest point meets the nearest target point |
| ⬇ **Snap to Ground** | Lowers the object until its bottom face rests on the highest surface below it |
| 👁 **Preview** | Shows where the object would move — without actually moving it |
| ✕ **Clear** | Hides the preview panel |

All actions support **Undo/Redo** (Ctrl+Z / Ctrl+Y).

---

## 🎯 Supported Object Types

**Source (selectable):**
- Any `Node3D` and subclasses

**Targets:**
- `MeshInstance3D` — full support via `MeshDataTool` (vertices, edges, faces)
- `CSGBox3D`, `CSGSphere3D`, `CSGCylinder3D`, `CSGTorus3D`, `CSGPolygon3D`,
  `CSGCombiner3D` — snapping via AABB (corners, edge midpoints, face centres)

---

## 📱 Mobile Editor (Android)

Designed from the ground up to work **without keyboard or mouse**:
- All actions are performed via buttons in the dock panel
- No keyboard shortcuts needed
- All settings accessible through the touch interface
- Works in the Godot Editor for Android (Godot 4.5+)

---

## 📂 File Structure

```
addons/snap3d/
├── plugin.cfg         — plugin metadata
├── plugin.gd          — EditorPlugin entry point
├── snap_manager.gd    — snapping logic
├── icon.svg           — plugin icon
└── ui/
    ├── snap_dock.gd   — dock panel controller
    └── snap_dock.tscn — dock panel scene
```

---

## ⚠️ Known Limitations

- CSG objects snap via AABB approximation (not real CSG geometry), because
  Godot 4 does not expose a public API for CSG mesh data in the editor.
  For precise geometry-based snapping, convert CSG objects to MeshInstance3D first.
- `PrimitiveMesh` types (BoxMesh, SphereMesh, etc.) are supported via conversion
  to `ArrayMesh`; if conversion fails, the object is skipped.

---

## 🔖 Version

`1.0.0` — compatible with Godot 4.5+, tested on 4.5 and 4.7 beta1.
