class_name DotWithRope
extends Node2D

@export var impulseStrength: float = 500.0

@onready var dotEntity: Entity = $DotEntity



func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouseEvent: InputEventMouseButton = event as InputEventMouseButton
		if mouseEvent.button_index == MOUSE_BUTTON_LEFT and mouseEvent.pressed:
			applyRandomImpulse()


func applyRandomImpulse() -> void:
	if dotEntity == null:
		return

	var randomAngle: float = randf() * TAU
	var direction: Vector2 = Vector2(cos(randomAngle), sin(randomAngle))

	dotEntity.apply_central_impulse(direction * impulseStrength)
