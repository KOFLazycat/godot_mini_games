# Stacks the toasts in the corner. When one in the middle expires the others
# slide into the gap instead of snapping, which is most of the difference between
# this and a homemade notification stack.
class_name ToastLayer
extends CanvasLayer


const SLOT_HEIGHT := 56.0
const MARGIN := Vector2(26.0, 26.0)
const MAX_VISIBLE := 5

var _toasts: Array[JuiceToast] = []


func _init() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS


func push(
	message: String,
	color: Color = JuicePalette.PINK,
	hold: float = 1.4,
	icon: Texture2D = null
) -> JuiceToast:
	if _toasts.size() >= MAX_VISIBLE:
		_retire(_toasts[0])

	var toast := JuiceToast.new()
	toast.message = message
	toast.plate = color
	toast.hold = hold
	toast.icon = icon
	toast.set_anchors_preset(Control.PRESET_TOP_LEFT)
	toast.size = Vector2(toast.measured_width(), SLOT_HEIGHT)
	toast.position = _slot_position(toast, _toasts.size())
	add_child(toast)

	_toasts.append(toast)
	toast.finished.connect(_retire.bind(toast))
	toast.play()
	_reflow()
	return toast


func clear() -> void:
	for toast in _toasts.duplicate():
		if is_instance_valid(toast):
			toast.queue_free()
	_toasts.clear()


func _retire(toast: JuiceToast) -> void:
	if not is_instance_valid(toast):
		return
	_toasts.erase(toast)
	toast.queue_free()
	_reflow()


# Positions are plain top-left offsets. Anchored Controls read position
# relative to the anchor, which breaks once a toast is sized from its own text.
func _slot_position(toast: JuiceToast, index: int) -> Vector2:
	var screen := Vector2(1152, 648)
	var viewport := get_viewport()
	if viewport != null:
		screen = viewport.get_visible_rect().size
	return Vector2(
		screen.x - toast.size.x - MARGIN.x,
		MARGIN.y + index * SLOT_HEIGHT
	)


func _reflow() -> void:
	for i in _toasts.size():
		var toast := _toasts[i]
		if not is_instance_valid(toast):
			continue
		var target := _slot_position(toast, i)
		toast.position.x = target.x
		if absf(toast.position.y - target.y) < 0.5:
			continue
		var tween := toast.create_tween()
		tween.tween_property(toast, ^"position:y", target.y, 0.28) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
