class_name DotWithRope
extends Node2D

@export var impulseStrength: float = 500.0
@export var impulseDirection: Vector2 = Vector2.ZERO
@export var dotTextureFront: Texture

@onready var rope: Rope = $Rope
@onready var dotEntity: Entity = $DotEntity


func _ready() -> void:
	pass


func initialize(newRopeLength: float = 0.0, dotColor: Color = Color.WHITE) -> void:
	if rope != null and newRopeLength != 0.0:
		rope.rope_length = newRopeLength
	if dotEntity != null and dotEntity.sprite != null:
		var sp: Sprite2D = dotEntity.sprite as Sprite2D
		if sp != null:
			dotEntity.sprite.modulate = dotColor
			if dotTextureFront != null:
				sp.texture = dotTextureFront


func applyRandomImpulse() -> void:
	if dotEntity == null:
		return
	var direction: Vector2 = impulseDirection
	if direction == Vector2.ZERO:
		var randomAngle: float = randf() * TAU
		direction = Vector2(cos(randomAngle), sin(randomAngle))

	dotEntity.apply_central_impulse(direction * impulseStrength)
