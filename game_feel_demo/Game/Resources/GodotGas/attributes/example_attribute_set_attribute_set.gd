## An extended class for the attribute module: ExampleAttributeSet 
##
## @meta_addon: GodotGAS Version 1 (See plugin version for exact version)
## @meta_author: YulRun (https://YulRun.Dev) & 'Your Name Here'
## @meta_license: MIT (Default)

@tool
class_name ExampleAttributeSetAttributeSet extends AttributeSet

var health: AttributeData = AttributeData.new(100.0)
var max_health: AttributeData = AttributeData.new(100.0)
var min_health: AttributeData = AttributeData.new(10.0)
var damage: AttributeData = AttributeData.new(10.0)


## The safety pipeline: Clamps stats before they are officially changed.
func pre_attribute_change(attribute_name: String, proposed_value: float) -> float:
	match attribute_name:
		"health":
			return clamp(proposed_value, min_health.current_value, max_health.current_value)

	return proposed_value


## The reaction pipeline: Handles moving goalposts (e.g. MaxHealth dropping below Health).
func post_attribute_change(asc: Node, attribute_name: String, old_value: float, new_value: float) -> void:
	match attribute_name:
		"max_health":
			if health.current_value > new_value:
				asc._apply_attribute_change("health", new_value - health.current_value)
		"min_health":
			if health.current_value < new_value:
				asc._apply_attribute_change("health", new_value - health.current_value)
