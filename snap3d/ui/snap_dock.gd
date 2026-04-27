@tool
extends Control

## Snap3D Dock — full UI panel for the snap plugin (no keyboard/mouse required)

var snap_manager  # SnapManager node
var plugin        # EditorPlugin

# UI references — assigned manually (no @onready in editor tool plugins)
var lbl_selection: Label
var btn_snap_apply: Button
var btn_snap_ground: Button
var btn_preview: Button
var btn_clear_preview: Button
var opt_mode: OptionButton
var opt_target: OptionButton
var spin_radius: SpinBox
var chk_rotation: CheckBox
var chk_preview: CheckBox
var panel_preview: PanelContainer
var lbl_preview_results: RichTextLabel

func _ready() -> void:
	# Wait one frame so the scene tree is fully built before searching nodes
	await get_tree().process_frame
	_find_nodes()
	_setup_options()
	_connect_signals()
	_update_ui_state()

func _find_nodes() -> void:
	lbl_selection       = find_child("LblSelection",      true, false) as Label
	btn_snap_apply      = find_child("BtnSnapApply",      true, false) as Button
	btn_snap_ground     = find_child("BtnSnapGround",     true, false) as Button
	btn_preview         = find_child("BtnPreview",        true, false) as Button
	btn_clear_preview   = find_child("BtnClearPreview",   true, false) as Button
	opt_mode            = find_child("OptMode",           true, false) as OptionButton
	opt_target          = find_child("OptTarget",         true, false) as OptionButton
	spin_radius         = find_child("SpinRadius",        true, false) as SpinBox
	chk_rotation        = find_child("ChkRotation",       true, false) as CheckBox
	chk_preview         = find_child("ChkPreview",        true, false) as CheckBox
	panel_preview       = find_child("PreviewSection",    true, false) as PanelContainer
	lbl_preview_results = find_child("LblPreviewResults", true, false) as RichTextLabel

func _setup_options() -> void:
	if opt_mode == null or opt_target == null:
		return

	opt_mode.clear()
	opt_mode.add_item("Vertex", 0)
	opt_mode.add_item("Edge", 1)
	opt_mode.add_item("Surface", 2)
	opt_mode.add_item("Origin", 3)
	opt_mode.selected = 0

	opt_target.clear()
	opt_target.add_item("All objects", 0)
	opt_target.add_item("CSG only", 1)
	opt_target.add_item("MeshInstance3D only", 2)
	opt_target.selected = 0

	if spin_radius:
		spin_radius.min_value = 0.01
		spin_radius.max_value = 50.0
		spin_radius.step = 0.05
		spin_radius.value = 0.5

	if chk_rotation:
		chk_rotation.button_pressed = false
	if chk_preview:
		chk_preview.button_pressed = true
	if panel_preview:
		panel_preview.visible = false

func _connect_signals() -> void:
	if btn_snap_apply:
		btn_snap_apply.pressed.connect(_on_btn_snap_apply)
	if btn_snap_ground:
		btn_snap_ground.pressed.connect(_on_btn_snap_ground)
	if btn_preview:
		btn_preview.pressed.connect(_on_btn_preview)
	if btn_clear_preview:
		btn_clear_preview.pressed.connect(_on_btn_clear_preview)
	if opt_mode:
		opt_mode.item_selected.connect(_on_mode_changed)
	if opt_target:
		opt_target.item_selected.connect(_on_target_changed)
	if spin_radius:
		spin_radius.value_changed.connect(_on_radius_changed)
	if chk_rotation:
		chk_rotation.toggled.connect(_on_rotation_toggled)
	if chk_preview:
		chk_preview.toggled.connect(_on_preview_toggled)

# ─── Button handlers ───────────────────────────────────────────────────────────

func _on_btn_snap_apply() -> void:
	if snap_manager:
		snap_manager.apply_snap_to_selected()

func _on_btn_snap_ground() -> void:
	if snap_manager:
		snap_manager.apply_snap_to_ground()

func _on_btn_preview() -> void:
	if snap_manager:
		snap_manager.preview_snap()

func _on_btn_clear_preview() -> void:
	if snap_manager:
		snap_manager.clear_preview()

func _on_mode_changed(idx: int) -> void:
	if snap_manager:
		snap_manager.snap_mode = idx

func _on_target_changed(idx: int) -> void:
	if snap_manager:
		snap_manager.snap_target = idx

func _on_radius_changed(val: float) -> void:
	if snap_manager:
		snap_manager.snap_radius = val

func _on_rotation_toggled(val: bool) -> void:
	if snap_manager:
		snap_manager.snap_rotation = val

func _on_preview_toggled(val: bool) -> void:
	if snap_manager:
		snap_manager.show_preview = val

# ─── Called by SnapManager ─────────────────────────────────────────────────────

func _refresh_selection_label(nodes: Array) -> void:
	if lbl_selection == null or btn_snap_apply == null:
		return
	if nodes.is_empty():
		lbl_selection.text = "Select Node3D object(s)"
		lbl_selection.modulate = Color(0.7, 0.7, 0.7)
		btn_snap_apply.disabled = true
		btn_snap_ground.disabled = true
		btn_preview.disabled = true
	else:
		var names: Array = []
		for n in nodes:
			names.append(n.name)
		lbl_selection.text = "✔ " + ", ".join(names)
		lbl_selection.modulate = Color(0.4, 1.0, 0.6)
		btn_snap_apply.disabled = false
		btn_snap_ground.disabled = false
		btn_preview.disabled = false

func _show_preview_results(results: Array) -> void:
	if panel_preview == null or lbl_preview_results == null:
		return
	panel_preview.visible = true
	if results.is_empty():
		lbl_preview_results.text = "[color=orange]No snap targets found[/color]"
		return
	var lines: Array = ["[b]Preview results:[/b]"]
	for r in results:
		var p: Vector3 = r.result.position
		var dist: float = r.result.distance
		lines.append(
			"[color=cyan]%s[/color] → (%.2f, %.2f, %.2f)  [color=gray]dist: %.3f[/color]" % [
				r.node.name, p.x, p.y, p.z, dist
			]
		)
	lbl_preview_results.text = "\n".join(lines)

func _clear_preview_results() -> void:
	if panel_preview == null:
		return
	panel_preview.visible = false
	lbl_preview_results.text = ""

func _update_ui_state() -> void:
	if btn_snap_apply == null:
		return
	btn_snap_apply.disabled = true
	btn_snap_ground.disabled = true
	btn_preview.disabled = true
