extends CanvasLayer
## 页面转场效果
## 🔒 商业版独占

@onready var rect = $TransitionRect

enum TransitionType {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	ZOOM_IN,
	ZOOM_OUT,
	PIXELATE,
	CIRCLE_EXPAND,
	CIRCLE_SHRINK
}

var transition_color = Color.BLACK


func play_transition(type: String = "fade", duration: float = 0.5) -> void:
	match type.to_lower():
		"fade":
			await play_fade(duration)
		"slide_left":
			await play_slide(duration, Vector2.LEFT)
		"slide_right":
			await play_slide(duration, Vector2.RIGHT)
		"slide_up":
			await play_slide(duration, Vector2.UP)
		"slide_down":
			await play_slide(duration, Vector2.DOWN)
		"zoom_in", "zoom":
			await play_zoom(duration, true)
		"zoom_out":
			await play_zoom(duration, false)
		"pixelate":
			await play_pixelate(duration)
		_:
			await play_fade(duration)


func play_fade(duration: float) -> void:
	if not rect:
		return
	
	rect.color = Color(transition_color.r, transition_color.g, transition_color.b, 0)
	
	var tween = create_tween()
	# 淡入
	tween.tween_property(rect, "color:a", 1.0, duration * 0.5)
	# 保持
	tween.tween_interval(0.1)
	# 淡出
	tween.tween_property(rect, "color:a", 0.0, duration * 0.5)
	
	await tween.finished


func play_slide(duration: float, direction: Vector2) -> void:
	if not rect:
		return
	
	rect.color = transition_color
	var viewport_size = get_viewport().get_visible_rect().size
	
	# 计算起始和结束位置
	var start_offset = direction * viewport_size
	var end_offset = -direction * viewport_size
	
	rect.position = start_offset
	
	var tween = create_tween()
	# 滑入
	tween.tween_property(rect, "position", Vector2.ZERO, duration * 0.4)
	# 保持
	tween.tween_interval(0.1)
	# 滑出
	tween.tween_property(rect, "position", end_offset, duration * 0.4)
	
	await tween.finished
	rect.position = Vector2.ZERO


func play_zoom(duration: float, zoom_in: bool) -> void:
	if not rect:
		return
	
	rect.color = transition_color
	rect.pivot_offset = get_viewport().get_visible_rect().size / 2
	
	var start_scale = Vector2.ZERO if zoom_in else Vector2.ONE
	var end_scale = Vector2.ONE if zoom_in else Vector2(10, 10)
	
	rect.scale = start_scale
	rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 缩放动画
	tween.tween_property(rect, "scale", Vector2.ONE, duration * 0.5)
	tween.tween_property(rect, "modulate:a", 1.0, duration * 0.3)
	
	await get_tree().create_timer(duration * 0.5).timeout
	
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(rect, "scale", end_scale, duration * 0.5)
	tween2.tween_property(rect, "modulate:a", 0.0, duration * 0.5)
	
	await tween2.finished
	rect.scale = Vector2.ONE


func play_pixelate(duration: float) -> void:
	# TODO: 需要配合 Shader 实现像素化效果
	# 这里先使用简单的淡入淡出代替
	await play_fade(duration)
