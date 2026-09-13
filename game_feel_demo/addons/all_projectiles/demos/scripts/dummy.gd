class_name DummyTest
extends CharacterBody2D


@export var floor_offset: float = 128.0
static var display_type: DisplayType = DisplayType.DAMAGE_PER_SECOND

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Label

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer



var frame_slices: Array[FrameSlice]
var inactive_damage_queue: Array[int]

var damage_on_this_frame: float
var cummulative_damage: float
var last_damage: float


enum DisplayType{
	DAMAGE_PER_SECOND, CUMULATIVE, LAST_ONE
}

class FrameSlice:
	var is_active: bool
	var damage: float
	var delta_time: float

	func _init(_damage: float, _delta_time: float) -> void:
		is_active = true
		damage = _damage
		delta_time = _delta_time





static func cycle_mode() -> void:
	var buffer: int = display_type + 1
	if (buffer >= DisplayType.size()):
		buffer = 0

	display_type = buffer as DisplayType
	

func restart_count() -> void:
	cummulative_damage = 0
	last_damage = 0


func _process(delta: float) -> void:
	add_frame_damage_to_queue(damage_on_this_frame, delta)
	update_damage_times(delta)
	damage_on_this_frame = 0





func add_frame_damage_to_queue(_damage: float, _delta_time: float) -> void:
	if (inactive_damage_queue.size() > 0):
		var id: int = inactive_damage_queue.pop_front()
		frame_slices[id]._init(_damage, _delta_time)
	else:
		frame_slices.push_back(FrameSlice.new(_damage, _delta_time))


func update_damage_times(_delta_time: float) -> void:
	for i: int in frame_slices.size():

		if (!frame_slices[i].is_active):
			continue

		frame_slices[i].delta_time += _delta_time
		if (frame_slices[i].delta_time > 1):

			frame_slices[i].is_active = false
			frame_slices[i].delta_time = 0
			inactive_damage_queue.push_back(i)


func get_mean() -> float:
	var cummulative: float = 0
	for i: int in frame_slices.size():
		if (frame_slices[i].is_active):
			cummulative += frame_slices[i].damage
	return cummulative





func _physics_process(delta: float) -> void:
	# Add the gravity.
	if !is_on_floor():
		velocity += get_gravity() * delta
	
	if (position.y >= 0 - floor_offset):
		velocity.y = 0;

	move_and_slide()



func damage(_proj: Projectile2D) -> void:
	damage_on_this_frame += _proj.resource.damage
	cummulative_damage += _proj.resource.damage
	last_damage = _proj.resource.damage
	update_label()
	play_animation(_proj.transform.origin)
	audio.pitch_scale = randf_range(0.85, 1.15)
	audio.play()


func update_label() -> void:
	if (display_type == DisplayType.DAMAGE_PER_SECOND):
		label.text = str(int(get_mean() + damage_on_this_frame))
		# if (get_mean() == 0):
		# 	label.text = str(last_damage)
		# else:
		# 	label.text = str(get_mean() + damage_on_this_frame)
	elif (display_type == DisplayType.CUMULATIVE):
		label.text = str(int(cummulative_damage))
	elif (display_type == DisplayType.LAST_ONE):
		label.text = str(int(last_damage))


func play_animation(proj_pos: Vector2) -> void:
	if (proj_pos.x < position.x):
		animator.play("back_hit")
		animator.clear_queue()
		animator.queue("back_overshoot")
	else: 
		animator.play("front_hit")
		animator.clear_queue()
		animator.queue("front_overshoot")




func _enter_tree() -> void:
	add_to_group("dummy")

func _exit_tree() -> void:
	remove_from_group("dummy")
