extends Node2D


@export var player: FrogCharacter
@export var curtain_node: Node2D

@export_group("Labels")
@export var labels: Array[Label]
@export var label_offset: Vector2
@export var blue_color: Color
@export var red_color: Color
@export_group("")

# Variables for the labels (numbers) on the grid
var multiple: float = 500.0
var multiple_offset: float = 3.0
var previous_round_pos: float
var current_round_pos: float
var is_red: bool

# Variables for stopping pause projectile cheese
var is_paused: bool
var pause_in_next_frame: bool
var has_entered_frame_mode: bool
var total_paused_time: float
var delta_paused_time: float
var start_pause: int

# Variables for cameras
@export_group("Cameras")
@export var fixed_camera: Camera2D
@onready var follow_camera: Camera2D = player.get_node("FollowCamera")
@onready var camera_indicator: CanvasLayer = fixed_camera.get_node("Indicator")
@export var camera_speed: float = 1.5
@export var camera_aceleration: float = 2.5
var is_dragging: bool
var previous_pos: Vector2

# Variables for the console information && pause menu
@export_group("UI")
@export var pause_menu: CanvasLayer
@export var console: TextEdit
var console_tween: Tween
@export var continue_button: Button
@export var restart_button: Button
@export var exit_button: Button
@export var show_controls_button: Button
@export var controls_panel: Panel

# Variables for prefabricated scenes
@export_group("Prefab")
@export var dummy_prefab: PackedScene


func _ready() -> void:
	previous_round_pos = 0
	is_red = true
	is_paused = false
	pause_in_next_frame = false
	has_entered_frame_mode = false
	is_dragging = false

	continue_button.pressed.connect(func() -> void: change_pause_state(false))
	restart_button.pressed.connect(func() -> void: get_tree().paused = false; get_tree().reload_current_scene())
	exit_button.pressed.connect(func() -> void: change_pause_state(false))
	show_controls_button.pressed.connect(func() -> void: controls_panel.visible = !controls_panel.visible)
	
	Engine.max_fps = 60


func update_console_text(text: String, pause_mode: int = Tween.TWEEN_PAUSE_STOP) -> void:
	if (console_tween):
		console_tween.kill()
	
	console.text = text
	console.modulate = Color(1,1,1,1)
	console_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN).set_pause_mode(pause_mode)
	console_tween.tween_property(console, "modulate", Color(1,1,1,0), 1.25).set_delay(1.8)


func change_pause_state(pause_state: bool) -> void:
	is_paused = pause_state
	get_tree().paused = is_paused
	pause_menu.visible = is_paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if event is InputEventKey:
		var button_event: InputEventKey = event as InputEventKey
		if (button_event.pressed):
			match button_event.keycode:
				KEY_ESCAPE, KEY_P:
					if (is_paused):
						start_pause = Time.get_ticks_msec()
					else:
						delta_paused_time = (Time.get_ticks_msec() - start_pause) / 1000.0
						total_paused_time += delta_paused_time
					change_pause_state(!is_paused)
					if (has_entered_frame_mode):
						update_console_text("  UPDATE_MODE changed to REAL_TIME", Tween.TWEEN_PAUSE_PROCESS)
					has_entered_frame_mode = false
				KEY_TAB:
					DummyTest.cycle_mode()
					get_tree().call_group("dummy", "restart_count")
					update_console_text("  Dummy's damage DISPLAY_MODE changed to \"%s\"" % DummyTest.DisplayType.keys()[DummyTest.display_type])
				KEY_COMMA:
					var instance: DummyTest = dummy_prefab.instantiate()
					instance.position = get_global_mouse_position()
					get_tree().current_scene.add_child(instance)
					update_console_text("  New Dummy added to the scene")
				KEY_PERIOD:
					get_tree().call_group("dummy", "queue_free")
					update_console_text("  All Dummies removed")
				KEY_N:
					update_console_text("  Added \"PROJECTILE_BUFF\" Modifier for (1) second (REFRESHABLE)")
				KEY_M:
					update_console_text("  Added \"ATTACK_BUFF\" Modifier for (1) second (REFRESHABLE)")


	elif event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event as InputEventMouseButton
		if (button_event.pressed):
			match button_event.button_index:
				MOUSE_BUTTON_RIGHT:
					if (fixed_camera.is_current()):
						follow_camera.make_current()
						camera_indicator.visible = false
						curtain_node.reparent(follow_camera, false)
						update_console_text("  CAMERA_MODE changed to FOLLOW")
					else:
						fixed_camera.global_position = follow_camera.global_position
						fixed_camera.make_current()
						camera_indicator.visible = true
						curtain_node.reparent(fixed_camera, false)
						update_console_text("  CAMERA_MODE changed to FIXED")
				MOUSE_BUTTON_MIDDLE:
					if (!fixed_camera.is_current()):
						fixed_camera.global_position = follow_camera.global_position
						fixed_camera.make_current()
						camera_indicator.visible = true
						curtain_node.reparent(fixed_camera, false)
						update_console_text("  CAMERA_MODE changed to FIXED")
					is_dragging = true
					previous_pos = get_global_mouse_position() * camera_speed + fixed_camera.position
				MOUSE_BUTTON_WHEEL_DOWN:
					update_console_text("  MAIN_ATTACK changed to \"%s\"" % player.cycle_weapons(1))
				MOUSE_BUTTON_WHEEL_UP:
					update_console_text("  MAIN_ATTACK changed to \"%s\"" % player.cycle_weapons(-1))
		elif (button_event.button_index == MOUSE_BUTTON_MIDDLE):
			is_dragging = false



func _process(_delta: float) -> void:

	if (!is_paused && pause_in_next_frame):
		is_paused = true
		pause_in_next_frame = false
		get_tree().paused = is_paused
	if (Input.is_action_just_pressed("ui_right") && is_paused && !pause_in_next_frame):
		change_pause_state(false)
		pause_in_next_frame = true
		if (!has_entered_frame_mode):
			update_console_text("  UPDATE_MODE changed to FRAME_BY_FRAME (Unpause to exit)", Tween.TWEEN_PAUSE_PROCESS)
			has_entered_frame_mode = true
		


	if (is_dragging):
		fixed_camera.position = fixed_camera.position.lerp(previous_pos - get_global_mouse_position() * camera_speed, _delta * camera_aceleration)

	current_round_pos = round(player.position.x / multiple) * multiple
	if (current_round_pos != previous_round_pos):
		update_labels()
		previous_round_pos = current_round_pos



func update_labels() -> void:
	var label: Label
	if (current_round_pos > previous_round_pos):
		var expected_target: float = (current_round_pos / multiple) + multiple_offset
		label = labels.pop_front()

		label.position = (Vector2.RIGHT * expected_target * multiple) + label_offset
		label.text = str(abs(int((expected_target * multiple) / 100.0)))
		labels.push_back(label)
	else:
		var expected_target: float = (current_round_pos / multiple) - multiple_offset
		label = labels.pop_back()

		label.position = (Vector2.RIGHT * expected_target * multiple) + label_offset
		label.text = str(abs(int((expected_target * multiple) / 100.0)))
		labels.push_front(label)

	if (is_red):
		label.set("theme_override_colors/font_color", red_color)
	else:
		label.set("theme_override_colors/font_color", blue_color)
	is_red = !is_red
