@tool
extends EditorPlugin

const PLUGIN_NAME = "Snap3D"
const DOCK_SCENE = preload("res://addons/snap3d/ui/snap_dock.tscn")

var snap_dock: Control
var snap_manager: Node
var overlay: EditorPlugin  # for 3D viewport overlay

func _enter_tree() -> void:
	snap_manager = preload("res://addons/snap3d/snap_manager.gd").new()
	snap_manager.name = "Snap3DManager"
	snap_manager.editor_plugin = self
	add_child(snap_manager)

	snap_dock = DOCK_SCENE.instantiate()
	snap_dock.snap_manager = snap_manager
	snap_manager.dock = snap_dock
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, snap_dock)

	snap_dock.plugin = self
	snap_manager.plugin = self

	# Connect to scene tree changes
	get_editor_interface().get_selection().selection_changed.connect(
		snap_manager._on_selection_changed
	)

	print("[Snap3D] Plugin loaded.")

func _exit_tree() -> void:
	if snap_dock:
		remove_control_from_docks(snap_dock)
		snap_dock.queue_free()
	if snap_manager:
		snap_manager.queue_free()

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if snap_manager and snap_manager.is_snapping_active():
		return snap_manager.handle_viewport_input(viewport_camera, event)
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func get_plugin_name() -> String:
	return PLUGIN_NAME
