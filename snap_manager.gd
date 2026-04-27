@tool
extends Node

## Snap3D Manager — correct surface-aware snapping without keyboard/mouse

var plugin: EditorPlugin
var dock: Control
var editor_plugin: EditorPlugin

# Settings
var snap_mode: int = SnapMode.VERTEX
var snap_target: int = SnapTarget.ALL
var snap_radius: float = 0.5
var show_preview: bool = true
var snap_rotation: bool = false

# State
var selected_nodes: Array[Node3D] = []

enum SnapMode  { VERTEX = 0, EDGE = 1, SURFACE = 2, ORIGIN = 3 }
enum SnapTarget{ ALL = 0, CSG_ONLY = 1, MESH_ONLY = 2 }

# ── SnapResult ────────────────────────────────────────────────────────────────
class SnapResult:
	var valid: bool       = false
	var new_position: Vector3 = Vector3.ZERO  # where to move node.global_position
	var normal: Vector3   = Vector3.UP
	var has_normal: bool  = false
	var distance: float   = INF               # distance used for "best" ranking

# ── Point record returned by _get_snap_points ─────────────────────────────────
# { position: Vector3, normal?: Vector3 }

# =============================================================================
func is_snapping_active() -> bool:
	return not selected_nodes.is_empty()

func _on_selection_changed() -> void:
	selected_nodes.clear()
	var sel := editor_plugin.get_editor_interface().get_selection()
	for node in sel.get_selected_nodes():
		if node is Node3D:
			selected_nodes.append(node as Node3D)
	if dock:
		dock._refresh_selection_label(selected_nodes)

func handle_viewport_input(_camera: Camera3D, _event: InputEvent) -> int:
	return EditorPlugin.AFTER_GUI_INPUT_PASS

# =============================================================================
#  PUBLIC ACTIONS
# =============================================================================

func apply_snap_to_selected() -> void:
	if selected_nodes.is_empty():
		push_warning("[Snap3D] No nodes selected.")
		return
	var scene_root := editor_plugin.get_editor_interface().get_edited_scene_root()
	if not scene_root:
		push_warning("[Snap3D] No scene open.")
		return
	var candidates := _collect_candidates(scene_root)
	if candidates.is_empty():
		push_warning("[Snap3D] No snap targets found in scene.")
		return

	var undo_redo := editor_plugin.get_undo_redo()
	undo_redo.create_action("Snap3D: Snap to Point")

	for node in selected_nodes:
		var r := _compute_snap(node, candidates)
		if r.valid:
			undo_redo.add_do_property(node, "global_position", r.new_position)
			undo_redo.add_undo_property(node, "global_position", node.global_position)
			if snap_rotation and r.has_normal:
				undo_redo.add_do_property(node, "global_basis", _basis_from_normal(r.normal))
				undo_redo.add_undo_property(node, "global_basis", node.global_basis)

	undo_redo.commit_action()

# ---------------------------------------------------------------------------
func apply_snap_to_ground() -> void:
	"""Lower each selected object until its bottom face rests on the highest
	   surface below it."""
	if selected_nodes.is_empty():
		return
	var scene_root := editor_plugin.get_editor_interface().get_edited_scene_root()
	if not scene_root:
		return
	var candidates := _collect_candidates(scene_root)

	var undo_redo := editor_plugin.get_undo_redo()
	undo_redo.create_action("Snap3D: Snap to Ground")

	for node in selected_nodes:
		# Bottom of the source object in world space
		var src_aabb  := _get_world_aabb(node)
		var src_bot_y := src_aabb.position.y       # lowest Y of selected obj
		var origin_y  := node.global_position.y

		var best_surface_y := -INF
		var found := false

		for candidate in candidates:
			# Get all TOP face points of the candidate
			var top_pts := _get_top_surface_points(candidate)
			for pt in top_pts:
				var pt_y: float = pt.y
				# The surface must be below (or at) the bottom of the source object
				if pt_y <= src_bot_y + 0.001 and pt_y > best_surface_y:
					best_surface_y = pt_y
					found = true

		if found:
			# Move node so its bottom sits exactly on best_surface_y
			var offset := best_surface_y - src_bot_y
			var new_pos := node.global_position + Vector3(0, offset, 0)
			undo_redo.add_do_property(node, "global_position", new_pos)
			undo_redo.add_undo_property(node, "global_position", node.global_position)

	undo_redo.commit_action()

# ---------------------------------------------------------------------------
func preview_snap() -> void:
	if selected_nodes.is_empty():
		return
	var scene_root := editor_plugin.get_editor_interface().get_edited_scene_root()
	if not scene_root:
		return
	var candidates := _collect_candidates(scene_root)
	var results: Array = []
	for node in selected_nodes:
		var r := _compute_snap(node, candidates)
		if r.valid:
			results.append({node = node, result = r})
	if dock:
		dock._show_preview_results(results)

func clear_preview() -> void:
	if dock:
		dock._clear_preview_results()

# =============================================================================
#  CORE SNAP ALGORITHM
# =============================================================================

func _compute_snap(node: Node3D, candidates: Array) -> SnapResult:
	## Finds the candidate snap point whose distance to the nearest point on
	## the SOURCE object is minimal.  The node is then offset so that its
	## nearest point coincides with the candidate point.

	var best := SnapResult.new()

	# Source: collect snap points on the node being moved
	var src_points := _get_snap_points(node, snap_mode)

	for candidate in candidates:
		var tgt_points := _get_snap_points(candidate, snap_mode)

		for tpt in tgt_points:
			var tpt_pos: Vector3 = tpt.position

			# Find which source point is closest to this target point
			var closest_src_pos := Vector3.ZERO
			var closest_src_dist := INF
			for spt in src_points:
				var spt_pos: Vector3 = spt.position
				var d := spt_pos.distance_to(tpt_pos)
				if d < closest_src_dist:
					closest_src_dist = d
					closest_src_pos = spt_pos

			if closest_src_dist < best.distance:
				best.distance     = closest_src_dist
				# Offset: move node so src point lands on target point
				var delta         := tpt_pos - closest_src_pos
				best.new_position = node.global_position + delta
				best.valid        = true
				if tpt.has("normal"):
					best.normal     = tpt.normal
					best.has_normal = true

	return best

# =============================================================================
#  CANDIDATE COLLECTION
# =============================================================================

func _collect_candidates(root: Node) -> Array:
	var result: Array = []
	_walk(root, result)
	return result

func _walk(node: Node, out: Array) -> void:
	var ok := false
	match snap_target:
		SnapTarget.ALL:      ok = node is MeshInstance3D or node is CSGShape3D
		SnapTarget.CSG_ONLY: ok = node is CSGShape3D
		SnapTarget.MESH_ONLY:ok = node is MeshInstance3D
	if ok and not selected_nodes.has(node):
		out.append(node)
	for child in node.get_children():
		_walk(child, out)

# =============================================================================
#  SNAP POINT EXTRACTION
# =============================================================================

func _get_snap_points(node: Node3D, mode: int) -> Array:
	if node is MeshInstance3D:
		return _snap_points_mesh(node as MeshInstance3D, mode)
	elif node is CSGShape3D:
		return _snap_points_csg(node as CSGShape3D, mode)
	else:
		# Fallback: AABB of any Node3D
		return _snap_points_aabb_node(node, mode)

# ── MeshInstance3D ────────────────────────────────────────────────────────────
func _snap_points_mesh(mi: MeshInstance3D, mode: int) -> Array:
	var points: Array = []
	if mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return points

	var arr_mesh := _to_array_mesh(mi.mesh)
	if arr_mesh == null or arr_mesh.get_surface_count() == 0:
		return points

	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(arr_mesh, 0) != OK:
		return points

	var xf := mi.global_transform

	match mode:
		SnapMode.ORIGIN:
			points.append({position = mi.global_position})

		SnapMode.VERTEX:
			for i in mdt.get_vertex_count():
				points.append({position = xf * mdt.get_vertex(i)})

		SnapMode.EDGE:
			var seen: Dictionary = {}
			for i in mdt.get_edge_count():
				var va := xf * mdt.get_vertex(mdt.get_edge_vertex(i, 0))
				var vb := xf * mdt.get_vertex(mdt.get_edge_vertex(i, 1))
				var mid := (va + vb) * 0.5
				# add both endpoints and midpoint (deduplicated by approximate key)
				for p in [va, vb, mid]:
					var key := "%d,%d,%d" % [roundi(p.x*100), roundi(p.y*100), roundi(p.z*100)]
					if not seen.has(key):
						seen[key] = true
						points.append({position = p})

		SnapMode.SURFACE:
			for i in mdt.get_face_count():
				var va := xf * mdt.get_vertex(mdt.get_face_vertex(i, 0))
				var vb := xf * mdt.get_vertex(mdt.get_face_vertex(i, 1))
				var vc := xf * mdt.get_vertex(mdt.get_face_vertex(i, 2))
				var center := (va + vb + vc) / 3.0
				var n := (vb - va).cross(vc - va).normalized()
				# Flip normal if it points inward (toward mesh center)
				var to_center := mi.global_position - center
				if n.dot(to_center) > 0:
					n = -n
				points.append({position = center, normal = n})

	return points

# ── CSGShape3D ────────────────────────────────────────────────────────────────
func _snap_points_csg(csg: CSGShape3D, mode: int) -> Array:
	var aabb: AABB = csg.get_aabb()
	var xf   := csg.global_transform
	return _snap_points_from_aabb(aabb, xf, mode)

# ── Generic AABB fallback ─────────────────────────────────────────────────────
func _snap_points_aabb_node(node: Node3D, mode: int) -> Array:
	# VisualInstance3D has get_aabb(); others fall back to zero-size
	var aabb: AABB
	if node.has_method("get_aabb"):
		aabb = node.get_aabb()
	else:
		aabb = AABB(Vector3.ZERO, Vector3.ZERO)
	return _snap_points_from_aabb(aabb, node.global_transform, mode)

func _snap_points_from_aabb(aabb: AABB, xf: Transform3D, mode: int) -> Array:
	var points: Array = []
	var corners := _aabb_corners(aabb)

	match mode:
		SnapMode.ORIGIN:
			points.append({position = xf * aabb.get_center()})

		SnapMode.VERTEX:
			for c in corners:
				points.append({position = xf * c})

		SnapMode.EDGE:
			for mid in _aabb_edge_midpoints(corners):
				points.append({position = xf * mid})
			for c in corners:
				points.append({position = xf * c})

		SnapMode.SURFACE:
			for fd in _aabb_face_data(aabb):
				points.append({
					position = xf * fd.center,
					normal   = (xf.basis * fd.normal).normalized()
				})

	return points

# ── "top surface" helper for snap-to-ground ───────────────────────────────────
func _get_top_surface_points(node: Node3D) -> Array:
	"""Returns world-space Y positions of the top face points of a node."""
	var pts: Array = []

	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			return pts
		var arr_mesh := _to_array_mesh(mi.mesh)
		if arr_mesh == null:
			return pts
		var mdt := MeshDataTool.new()
		if mdt.create_from_surface(arr_mesh, 0) != OK:
			return pts
		var xf := mi.global_transform
		for i in mdt.get_vertex_count():
			pts.append(xf * mdt.get_vertex(i))
	elif node is CSGShape3D:
		var aabb: AABB = node.get_aabb()
		var xf   := node.global_transform
		for c in _aabb_corners(aabb):
			pts.append(xf * c)
	else:
		if node.has_method("get_aabb"):
			var aabb: AABB = node.get_aabb()
			var xf := node.global_transform
			for c in _aabb_corners(aabb):
				pts.append(xf * c)

	return pts

# =============================================================================
#  AABB HELPERS
# =============================================================================

func _aabb_corners(aabb: AABB) -> Array:
	var p := aabb.position
	var e := aabb.end
	return [
		Vector3(p.x, p.y, p.z), Vector3(e.x, p.y, p.z),
		Vector3(p.x, e.y, p.z), Vector3(e.x, e.y, p.z),
		Vector3(p.x, p.y, e.z), Vector3(e.x, p.y, e.z),
		Vector3(p.x, e.y, e.z), Vector3(e.x, e.y, e.z),
	]

func _aabb_edge_midpoints(corners: Array) -> Array:
	var edge_pairs := [
		[0,1],[2,3],[4,5],[6,7],
		[0,2],[1,3],[4,6],[5,7],
		[0,4],[1,5],[2,6],[3,7],
	]
	var mids: Array = []
	for ep in edge_pairs:
		mids.append((corners[ep[0]] + corners[ep[1]]) * 0.5)
	return mids

class FaceData:
	var center: Vector3
	var normal: Vector3

func _aabb_face_data(aabb: AABB) -> Array:
	var c := aabb.get_center()
	var h := aabb.size * 0.5
	var faces: Array = []
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		for sign in [1.0, -1.0]:
			var fd   := FaceData.new()
			fd.normal = axis * sign
			fd.center = c + fd.normal * h.dot(axis.abs())
			faces.append(fd)
	return faces

# =============================================================================
#  MESH CONVERSION
# =============================================================================

func _to_array_mesh(mesh: Mesh) -> ArrayMesh:
	if mesh is ArrayMesh:
		return mesh as ArrayMesh
	# PrimitiveMesh (BoxMesh, SphereMesh, etc.) → ArrayMesh
	if mesh is PrimitiveMesh:
		var pm  := mesh as PrimitiveMesh
		var am  := ArrayMesh.new()
		var arr := pm.get_mesh_arrays()
		if arr and arr.size() > 0:
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			return am
	return null

# =============================================================================
#  ROTATION HELPERS
# =============================================================================

func _basis_from_normal(normal: Vector3) -> Basis:
	var up := Vector3.UP
	if abs(normal.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right := normal.cross(up).normalized()
	var fwd   := normal.cross(right).normalized()
	return Basis(right, normal, -fwd)

# =============================================================================
#  WORLD AABB of a node (for snap-to-ground bottom calculation)
# =============================================================================

func _get_world_aabb(node: Node3D) -> AABB:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			return mi.global_transform * mi.mesh.get_aabb()
	if node.has_method("get_aabb"):
		return node.global_transform * node.get_aabb()
	# Fallback: treat as point
	return AABB(node.global_position, Vector3.ZERO)
