## Description
## Requirements: [Does this component depend on other components? Or does it need the parent Entity to be a specific type of node?]

class_name ASCComponent
extends Component


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame
## 当前实体所携带的 AbilitySystemComponent
@export var asc: AbilitySystemComponent:
	get:
		if asc == null:
			asc = entity.findFirstChildOfType(AbilitySystemComponent)
		return asc
@export var baseAblityScenes: Array[PackedScene]
#endregion


#region State
#endregion


#region Signals
#endregion


#region Dependencies
# WARNING: "Memoization" (caching the reference) may cause bugs if a component is removed from the entity later.
@onready var timer: Timer = $Timer
@onready var inputComponent: InputComponent:
	get:
		if inputComponent == null:
			inputComponent = entity.getComponent(InputComponent)
		return inputComponent

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return []

#endregion


func _ready() -> void:
	# PLACEHOLDER: Add any code needed to configure and prepare the component.
	# Apply setters because Godot doesn't on _ready()
	if asc == null:
		printError("AbilitySystemComponent 缺失，组件无法正常工作")
		isEnabled = false
	self.set_process(isEnabled)
	initializeAbility()
	
	#asc.bind_ability_to_input(fireball_ability, 1)
	Tools.connectSignal(inputComponent.didUpdateInputActionsList, self.onInputComponent_didUpdateInputActionsList)
	Tools.connectSignal(timer.timeout, onTimer_timeout)


func initializeAbility() -> void:
	for i: int in range(baseAblityScenes.size()):
		var ab: PackedScene = baseAblityScenes[i]
		if ab != null:
			var ga: GameplayAbility = ab.instantiate()
			if ga != null:
				# Grant the ability to the ASC
				asc.grant_ability(ga)
				# Bind the Fireball ability to Input ID '1'
				asc.bind_ability_to_input(ga, i + 1)


func _process(_delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	if not isEnabled: return
	pass # PLACEHOLDER: Perform any per-frame updates.


#region Signal Handler

func onTimer_timeout() -> void:
	#asc.send_gameplay_event(GameplayTags.Example_Event_Fireball_Shoot)
	pass


func onInputComponent_didUpdateInputActionsList(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(GlobalInput.Actions.fire):
		# Tell the ASC that Input ID 1 was pressed
		asc.ability_local_input_pressed(1)
	if Input.is_action_just_released(GlobalInput.Actions.fire):
		# Tell the ASC that Input ID 1 was released (Useful for charging attacks!)
		asc.ability_local_input_released(1)

#endregion
