# 🧲 Snap3D — Магнитная привязка 3D объектов для Godot 4

Плагин для привязки (примагничивания) 3D объектов в Godot 4.x без зависимости
от клавиатуры и мыши. Полностью работает в мобильном редакторе на Android.

---

## 📦 Установка

1. Скопируй папку `addons/snap3d` в корень своего Godot проекта.
2. Открой **Project → Project Settings → Plugins**.
3. Найди `Snap3D` и нажми **Enable**.
4. В правой панели редактора появится вкладка **🧲 Snap3D**.

---

## 🚀 Использование

### Шаг 1 — Выделение
Выдели один или несколько `Node3D`-совместимых объектов в сцене
(нажатием на них в 3D вьюпорте или в дереве сцены).
Панель покажет, что выделено.

### Шаг 2 — Настройка

| Параметр | Описание |
|---|---|
| **Режим** | Точка привязки: Вершина / Ребро / Поверхность / Начало координат |
| **Цель** | Что считается целью: Все объекты / Только CSG / Только MeshInstance3D |
| **Радиус (м)** | Максимальное расстояние поиска от выделенного объекта |
| **Выравнивать по нормали** | Поворачивать объект по нормали поверхности привязки |
| **Предпросмотр** | Показывать в панели, куда переместится объект |

### Шаг 3 — Действие

| Кнопка | Действие |
|---|---|
| 🧲 **Привязать к ближайшей точке** | Перемещает выделенный объект к ближайшей вершине/ребру/грани цели |
| ⬇ **Опустить на поверхность** | Опускает объект вниз до первой поверхности под ним |
| 👁 **Предпросмотр** | Показывает координаты цели без перемещения |
| ✕ **Сбросить** | Скрывает панель предпросмотра |

Все действия поддерживают **Undo/Redo** (Ctrl+Z / Ctrl+Y).

---

## 🎯 Поддерживаемые типы объектов

**Для привязки (выделяемые):**
- Любые `Node3D` и наследники

**В качестве целей:**
- `MeshInstance3D` — полная поддержка через `MeshDataTool` (вершины, рёбра, грани)
- `CSGBox3D`, `CSGSphere3D`, `CSGCylinder3D`, `CSGTorus3D`, `CSGPolygon3D`,
  `CSGCombiner3D` — привязка по AABB (углы, середины рёбер, центры граней)

---

## 📱 Мобильный редактор (Android)

Плагин разработан специально для работы **без клавиатуры и мыши**:
- Все действия выполняются кнопками в панели
- Никаких сочетаний клавиш не требуется
- Все настройки доступны через тач-интерфейс
- Работает в Godot Editor для Android (Godot 4.5+)

---

## 📂 Структура файлов

```
addons/snap3d/
├── plugin.cfg         — метаданные плагина
├── plugin.gd          — точка входа EditorPlugin
├── snap_manager.gd    — логика привязки
└── ui/
    ├── snap_dock.gd   — контроллер панели
    └── snap_dock.tscn — сцена панели
```

---

## ⚠️ Известные ограничения

- CSG объекты привязываются по аппроксимации AABB (не по реальной геометрии),
  так как Godot 4 не предоставляет публичный API для CSG меша в Editor.
- Для точной привязки по геометрии CSG рекомендуется предварительно
  конвертировать их в MeshInstance3D.
- `PrimitiveMesh` (BoxMesh, SphereMesh и т.д.) поддерживается через конвертацию
  в ArrayMesh; если конвертация невозможна, объект пропускается.

---

## 🔖 Версия

`1.0.0` — совместимо с Godot 4.2+, протестировано на 4.5 и 4.7 beta1.

---

---

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

`1.0.0` — compatible with Godot 4.2+, tested on 4.5 and 4.7 beta1.
