class_name TacticsControlsInputService
extends RefCounted
## Service class for managing input-related functionalities in the Tactics game.

var controls: TacticsControlsResource
var input_capture: Node

func _init(_controls: TacticsControlsResource, _input_capture: Node) -> void:
	controls = _controls
	input_capture = _input_capture

func update_mouse_mode() -> void:
	Input.set_mouse_mode(int(controls.is_joystick))

func handle_input(event: InputEvent) -> void:
	controls.is_joystick = event is InputEventJoypadButton or event is InputEventJoypadMotion

## Gets the 3D position of the mouse in the game world.
## Returns a BaseTile or Pawn. Returns null if hovering over a UI element.
## Converts StaticBody3D hits to their corresponding ProceduralTile.
func get_3d_canvas_mouse_position(collision_mask: int, ctrl: TacticsControls) -> Variant:
	if is_mouse_hovering_ui_elem(ctrl):
		return null
	
	if input_capture:
		var hit = input_capture.project_mouse_position(collision_mask, controls.is_joystick)
		
		# ===== Conversion: StaticBody3D → ProceduralTile =====
		if hit is StaticBody3D and hit.has_meta("tile_data"):
			return hit.get_meta("tile_data") as BaseTile
		
		return hit
	else:
		push_error("InputCapture node not found")
		return null

func is_mouse_hovering_ui_elem(
		ctrl: TacticsControls, elm: Array[String] = TacticsConfig.ui_elem) -> bool:
	for e: String in elm:
		if ctrl.get_node(e).visible:
			match e:
				"%Actions":
					for action: Button in ctrl.get_node(e).get_children():
						if action.get_global_rect().has_point(ctrl.get_viewport().get_mouse_position()): 
							return true
				"%Hints":
					for hint: TextureRect in ctrl.get_node(e).get_children():
						if hint.get_global_rect().has_point(ctrl.get_viewport().get_mouse_position()): 
							return true
	return false
