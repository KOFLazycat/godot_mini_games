# Every tunable number in one resource, so you can change how the kit feels from
# the inspector instead of digging through code.
@tool
class_name JuiceConfig
extends Resource


@export_group("Master")
@export var enabled: bool = true
@export_range(0.0, 2.0, 0.01) var master_intensity: float = 1.0

@export_group("Screen Shake")
@export var shake_max_offset: Vector2 = Vector2(26.0, 18.0)
@export_range(0.0, 0.5, 0.001) var shake_max_roll: float = 0.06
@export_range(0.1, 10.0, 0.05) var shake_decay: float = 2.4
@export_range(1.0, 120.0, 1.0) var shake_frequency: float = 42.0
@export_range(1.0, 4.0, 0.1) var shake_power: float = 2.0

@export_group("Hitstop")
@export_range(0.0, 1.0, 0.01) var hitstop_scale: float = 0.0
@export_range(0.0, 1.0, 0.01) var hitstop_duration: float = 0.08

@export_group("Slow Motion")
@export_range(0.01, 1.0, 0.01) var slowmo_scale: float = 0.35
@export_range(0.0, 10.0, 0.05) var slowmo_duration: float = 0.6
@export_range(0.0, 2.0, 0.01) var slowmo_blend_in: float = 0.05
@export_range(0.0, 2.0, 0.01) var slowmo_blend_out: float = 0.25

@export_group("Punch / Squash & Stretch")
@export_range(0.0, 2.0, 0.01) var punch_amount: float = 0.25
@export_range(0.01, 2.0, 0.01) var punch_duration: float = 0.32
@export_range(0.0, 1.0, 0.01) var squash_amount: float = 0.3

@export_group("Screen Effects")
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 0.55)
@export_range(0.0, 2.0, 0.01) var flash_duration: float = 0.12
@export_range(0.0, 0.05, 0.0005) var chromatic_amount: float = 0.006
@export_range(0.0, 2.0, 0.01) var chromatic_duration: float = 0.22

@export_group("Hit Flash")
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var hit_flash_duration: float = 0.09

@export_group("Damage Numbers")
@export_range(0.1, 5.0, 0.05) var damage_number_lifetime: float = 0.9
@export_range(0.0, 600.0, 5.0) var damage_number_rise: float = 130.0
@export_range(0.0, 200.0, 1.0) var damage_number_spread: float = 34.0
@export var damage_number_color: Color = Color(1.0, 0.96, 0.85)
@export var damage_number_crit_color: Color = Color(1.0, 0.72, 0.22)

@export_group("Rumble")
@export_range(0.0, 1.0, 0.01) var rumble_weak: float = 0.35
@export_range(0.0, 1.0, 0.01) var rumble_strong: float = 0.55
@export_range(0.0, 2.0, 0.01) var rumble_duration: float = 0.18

@export_group("Audio")
@export var sfx_bus: StringName = &"Master"
@export var pitch_variation: Vector2 = Vector2(0.92, 1.08)
@export_range(0.0, 200.0, 1.0) var sfx_dedupe_ms: float = 25.0
@export_range(1, 64, 1) var sfx_voice_count: int = 24
