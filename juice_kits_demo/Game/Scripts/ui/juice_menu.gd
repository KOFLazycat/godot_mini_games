# Holds JuiceButtons, deals them in on a stagger, handles keyboard and mouse.
# Style is how a row enters, order is which row goes first. They are separate
# settings because the same slide dealt centre-out feels nothing like the same
# slide dealt top to bottom.
class_name JuiceMenu
extends VBoxContainer


enum StaggerOrder {
	SEQUENTIAL,
	REVERSE,
	CENTRE_OUT,
	EDGES_IN,
	RANDOM,
	TOGETHER,
}

signal activated(id: StringName, index: int)
signal selection_changed(index: int)

@export var intro_style: JuiceButton.IntroStyle = JuiceButton.IntroStyle.SLIDE
@export var stagger_order: StaggerOrder = StaggerOrder.SEQUENTIAL
@export var stagger: float = 0.06
@export var wrap: bool = true
@export var autostart: bool = true
@export var keyboard_nav: bool = true

var index: int = 0

var _buttons: Array[JuiceButton] = []


func _ready() -> void:
	refresh_buttons()
	if autostart and visible:
		play_intro()
	set_process_unhandled_input(keyboard_nav and visible)


func refresh_buttons() -> void:
	_buttons.clear()
	for child in get_children():
		if child is JuiceButton:
			var button := child as JuiceButton
			_buttons.append(button)
			if not button.hovered.is_connected(_on_hovered):
				button.hovered.connect(_on_hovered.bind(button))
			if not button.pressed.is_connected(_on_pressed):
				button.pressed.connect(_on_pressed.bind(button))
	_refresh_selection()


func button_count() -> int:
	return _buttons.size()


func get_button(at: int) -> JuiceButton:
	return _buttons[at] if at >= 0 and at < _buttons.size() else null


func play_intro(from_left: bool = true) -> void:
	visible = true
	set_process_unhandled_input(keyboard_nav)
	index = 0
	_refresh_selection()
	for i in _buttons.size():
		_buttons[i].intro_style = intro_style
		_buttons[i].play_intro(_delay_for(i), from_left)


func play_outro(to_left: bool = false) -> float:
	set_process_unhandled_input(false)

	var last := 0.0
	for i in _buttons.size():
		last = maxf(last, _buttons[i].play_outro(_delay_for(i) * 0.6, to_left))

	if last > 0.0:
		await get_tree().create_timer(last).timeout
	visible = false
	return last


func _delay_for(at: int) -> float:
	var count := _buttons.size()
	if count <= 1 or stagger <= 0.0:
		return 0.0

	var step := 0.0
	match stagger_order:
		StaggerOrder.SEQUENTIAL:
			step = float(at)
		StaggerOrder.REVERSE:
			step = float(count - 1 - at)
		StaggerOrder.CENTRE_OUT:
			step = absf(float(at) - float(count - 1) * 0.5)
		StaggerOrder.EDGES_IN:
			var middle := float(count - 1) * 0.5
			step = middle - absf(float(at) - middle)
		StaggerOrder.RANDOM:
			# Seeded off the index so a row keeps its slot between replays. A
			# fresh randf() every time just looks broken.
			step = float(posmod(at * 7919, maxi(count, 1)))
		StaggerOrder.TOGETHER:
			step = 0.0

	return stagger * step


func preview(style: JuiceButton.IntroStyle, order: StaggerOrder) -> void:
	intro_style = style
	stagger_order = order
	play_intro()


func move(step: int) -> void:
	if _buttons.is_empty():
		return
	if wrap:
		index = wrapi(index + step, 0, _buttons.size())
	else:
		index = clampi(index + step, 0, _buttons.size() - 1)
	_refresh_selection()
	selection_changed.emit(index)


func select(at: int) -> void:
	if _buttons.is_empty():
		return
	index = clampi(at, 0, _buttons.size() - 1)
	_refresh_selection()
	selection_changed.emit(index)


func activate() -> void:
	if not _buttons.is_empty():
		_buttons[index].press()


func _unhandled_input(event: InputEvent) -> void:
	if _buttons.is_empty():
		return

	if event.is_action_pressed(&"ui_down"):
		move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		move(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		activate()
		get_viewport().set_input_as_handled()


func _refresh_selection() -> void:
	for i in _buttons.size():
		_buttons[i].set_selected(i == index)


func _on_hovered(button: JuiceButton) -> void:
	var found := _buttons.find(button)
	if found >= 0 and found != index:
		index = found
		_refresh_selection()
		selection_changed.emit(index)


func _on_pressed(button: JuiceButton) -> void:
	activated.emit(button.name, _buttons.find(button))
