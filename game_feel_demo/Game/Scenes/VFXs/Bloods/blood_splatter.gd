class_name BloodSplatter extends Node2D

@onready var sprite_2d = $Sprite2D
@export var sprite_sheet_frame_count = 4

@export_color_no_alpha var blood_dark_color : Color
@export_color_no_alpha var blood_light_color : Color

@export var min_travel_speed = 500.0 # pixels per second
@export var max_travel_speed = 700.0 # pixels per second
@export var in_air_scale = 0.4
@export var in_air_modulate_percent = 0.3 # 0 to 1, determines how dark blood is while flying through air

var base_color : Color

const GROUND_Z_INDEX = 1
const IN_AIR_Z_INDEX = 10

@export var max_blood_scale = 0.7
@export var min_blood_scale = 0.4

@export var chance_to_stretch = 0.2
@export var splatterSoundResource: SoundResource

var fly_direction = Vector2.RIGHT
var in_air = false
var final_pos : Vector2
@onready var final_scale : Vector2 = scale
@onready var final_angle : float = global_rotation

var loaded_from_save = false

@export var is_static = false

func _ready():
	if loaded_from_save:
		return
	randomize_blood_splatter()
	if is_in_group("instanced"):
		add_to_group("serializable")

func randomize_blood_splatter():
	sprite_2d.frame = randi_range(0, sprite_sheet_frame_count-1)
	if !is_static:
		sprite_2d.rotation = randf_range(0.0, TAU)
		sprite_2d.scale = Vector2.ONE*randf_range(min_blood_scale, max_blood_scale)
	base_color = blood_dark_color.lerp(blood_light_color, randf_range(0.0, 1.0))
	modulate = base_color

func fling_blood(start_pos: Vector2, end_pos: Vector2, play_splatter_sound=false):
	if is_static:
		return
	final_pos = end_pos
	fly_direction = start_pos.direction_to(end_pos)
	z_index = IN_AIR_Z_INDEX
	global_position = start_pos
	scale = Vector2.ONE * in_air_scale
	modulate = base_color.lerp(Color.BLACK, in_air_modulate_percent)
	if randf_range(0.0, 1.0) < chance_to_stretch:
		final_angle = fly_direction.angle()
		final_scale.y = final_scale.y * 0.7
		final_scale.x = final_scale.x * 1.4
	
	var travel_speed = randf_range(min_travel_speed, max_travel_speed)
	var travel_time = start_pos.distance_to(end_pos) / travel_speed
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", end_pos, travel_time)
	tween.tween_callback(on_hit_ground.bind(play_splatter_sound))

func on_hit_ground(play_splatter_sound=false):
	modulate = base_color
	z_index = GROUND_Z_INDEX
	global_rotation = final_angle
	scale = final_scale
	if play_splatter_sound and splatterSoundResource:
		splatterSoundResource.play_managed()
