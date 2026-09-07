# The demo scene, and the closest thing to an example. Every widget in here is
# wired to something you can press, and J turns all the juice off so you can
# compare the same screen with and without.
# The layout is built in code so this file reads top to bottom. In a real project
# you would place the widgets in the editor and never write any of this.
extends Control


const SCREEN_LOOKS := [
	ScreenFX.Look.OFF,
	ScreenFX.Look.SUBTLE,
	ScreenFX.Look.ARCADE,
	ScreenFX.Look.HANDHELD,
	ScreenFX.Look.BROKEN,
]
const LOOK_NAMES := ["OFF", "SUBTLE", "ARCADE", "HANDHELD", "BROKEN"]

const STYLE_NAMES := ["SLIDE", "DROP", "RISE", "POP", "FLIP", "FADE"]
const ORDER_NAMES := ["SEQUENTIAL", "REVERSE", "CENTRE-OUT", "EDGES-IN", "RANDOM", "TOGETHER"]

const INSTAGRAM_URL := "https://www.instagram.com/mii_misan"
const INSTAGRAM_HANDLE := "@MII_MISAN"
const GITHUB_URL := "https://github.com/Miisan-png"
const GITHUB_HANDLE := "MIISAN-PNG"
const DISCORD_URL := "https://discord.gg/fU9yU6KG96"
const DISCORD_HANDLE := "DISCORD"

var _score: JuiceCounter
var _combo: JuiceCounter
var _health: JuiceBar
var _energy: JuiceBar
var _menu: JuiceMenu
var _status: Label
var _tooltip: JuiceTooltip

var _look_index: int = 2
var _style_index: int = 0
var _order_index: int = 0
var _combo_count: int = 0
var _combo_timer: float = 0.0


func _ready() -> void:
	_build_backdrop()
	_build_title()
	_build_menu()
	_build_hud()
	_build_hints()
	_build_footer()

	Juice.set_look(SCREEN_LOOKS[_look_index], 0.8)
	await get_tree().create_timer(0.5).timeout
	Juice.toast("PRESS J TO A/B THE JUICE", JuicePalette.CYAN, 2.6)


func _process(delta: float) -> void:
	if _combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
			_combo.set_value(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_juice"):
		_toggle_juice()
	elif event.is_action_pressed(&"reset_demo"):
		_reset()


func _build_backdrop() -> void:
	var backdrop := JuiceBackdrop.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.sun_x = 0.43
	backdrop.sun_radius = 124.0
	add_child(backdrop)
	move_child(backdrop, 0)


func _build_title() -> void:
	var title := Label.new()
	title.text = "JUICE KIT"
	title.position = Vector2(64, 46)
	title.add_theme_font_override(&"font", JuicePalette.font())
	title.add_theme_font_size_override(&"font_size", 62)
	title.add_theme_color_override(&"font_color", JuicePalette.CREAM)
	title.add_theme_constant_override(&"shadow_offset_x", 6)
	title.add_theme_constant_override(&"shadow_offset_y", 6)
	title.add_theme_color_override(&"font_shadow_color", JuicePalette.INK)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "UI FEEL FOR GODOT 4"
	subtitle.position = Vector2(68, 118)
	subtitle.add_theme_font_override(&"font", JuicePalette.font())
	subtitle.add_theme_font_size_override(&"font_size", 17)
	subtitle.add_theme_color_override(&"font_color", JuicePalette.GOLD)
	add_child(subtitle)

	JuiceTween.pop_in(title, 0.6)
	var breathe := create_tween().set_loops()
	breathe.tween_property(title, ^"position:y", 50.0, 2.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(title, ^"position:y", 46.0, 2.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _build_menu() -> void:
	_menu = JuiceMenu.new()
	_menu.name = "Menu"
	_menu.position = Vector2(64, 170)
	_menu.custom_minimum_size = Vector2(340, 0)
	_menu.add_theme_constant_override(&"separation", 8)
	add_child(_menu)

	_add_button("Strike", "STRIKE", JuicePalette.RED)
	_add_button("Collect", "COLLECT", JuicePalette.MINT)
	_add_button("Glitch", "GLITCH", JuicePalette.CYAN)
	_add_button("Overload", "OVERLOAD", JuicePalette.GOLD)
	_add_button("Screen", "SCREEN: ARCADE", JuicePalette.PINK)
	_add_button("Style", "STYLE: SLIDE", JuicePalette.CYAN)
	_add_button("Order", "ORDER: SEQUENTIAL", JuicePalette.CYAN)

	var locked := _add_button("Locked", "LOCKED", JuicePalette.CREAM)
	locked.disabled = true

	_menu.refresh_buttons()
	_menu.activated.connect(_on_menu_activated)
	_menu.play_intro()


func _add_button(node_name: String, text: String, accent: Color) -> JuiceButton:
	var button := JuiceButton.new()
	button.name = node_name
	button.text = text
	button.fill_selected = accent
	button.font_size = 24
	button.custom_minimum_size = Vector2(340, 48)
	_menu.add_child(button)
	return button


func _build_hud() -> void:
	var panel_x := 720.0
	_build_hud_plate(panel_x)

	_score = _make_counter("SCORE", Vector2(panel_x, 214), 52, JuicePalette.CREAM)
	_score.group_digits = true

	_combo = _make_counter("COMBO", Vector2(panel_x, 322), 40, JuicePalette.GOLD)
	_combo.suffix = "x"

	_health = _make_bar("HEALTH", Vector2(panel_x, 430), JuicePalette.MINT, 0)
	_energy = _make_bar("ENERGY", Vector2(panel_x, 526), JuicePalette.CYAN, 8)
	_energy.fill_color = JuicePalette.CYAN
	_energy.ghost_color = JuicePalette.PINK


func _build_hud_plate(panel_x: float) -> void:
	var plate := ColorRect.new()
	plate.color = Color(0.04, 0.05, 0.10, 0.62)
	plate.position = Vector2(panel_x - 30.0, 190.0)
	plate.size = Vector2(526.0, 400.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)

	var edge := ColorRect.new()
	edge.color = JuicePalette.GOLD
	edge.position = Vector2(panel_x - 30.0, 190.0)
	edge.size = Vector2(4.0, 400.0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)


func _make_counter(caption: String, at: Vector2, font_size: int, color: Color) -> JuiceCounter:
	_add_caption(caption, at)

	var counter := JuiceCounter.new()
	counter.position = at + Vector2(0, 20)
	counter.size = Vector2(460, float(font_size) + 14.0)
	counter.font_size = font_size
	counter.color = color
	add_child(counter)
	return counter


func _make_bar(caption: String, at: Vector2, color: Color, segments: int) -> JuiceBar:
	_add_caption(caption, at)

	var bar := JuiceBar.new()
	bar.position = at + Vector2(0, 24)
	bar.size = Vector2(460, 34)
	bar.fill_color = color
	bar.segments = segments
	add_child(bar)
	return bar


func _add_caption(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_override(&"font", JuicePalette.font())
	label.add_theme_font_size_override(&"font_size", 15)
	label.add_theme_color_override(&"font_color", Color(0.78, 0.82, 0.98))
	label.add_theme_constant_override(&"shadow_offset_x", 2)
	label.add_theme_constant_override(&"shadow_offset_y", 2)
	label.add_theme_color_override(&"font_shadow_color", JuicePalette.INK)
	add_child(label)


func _build_hints() -> void:
	_status = Label.new()
	_status.position = Vector2(64, 630)
	_status.add_theme_font_override(&"font", JuicePalette.font())
	_status.add_theme_font_size_override(&"font_size", 15)
	_status.add_theme_constant_override(&"shadow_offset_x", 3)
	_status.add_theme_constant_override(&"shadow_offset_y", 3)
	_status.add_theme_color_override(&"font_shadow_color", JuicePalette.INK)
	add_child(_status)
	_refresh_status()

	var keys := Label.new()
	keys.text = "ARROWS / MOUSE  select      ENTER / CLICK  press      J  toggle juice      R  reset"
	keys.position = Vector2(64, 664)
	keys.add_theme_font_override(&"font", JuicePalette.font())
	keys.add_theme_font_size_override(&"font_size", 13)
	keys.add_theme_color_override(&"font_color", Color(0.55, 0.58, 0.75))
	add_child(keys)


func _build_footer() -> void:
	# One tooltip shared by every link, parented last so it draws over them.
	_tooltip = JuiceTooltip.new()
	_tooltip.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_tooltip)

	var links := [
		{"icon": "icon_discord", "label": DISCORD_HANDLE, "url": DISCORD_URL,
			"tint": Color("7d92f5"), "toast": "OPENING DISCORD",
			"tip": "where i yap to my community"},
		{"icon": "icon_github", "label": GITHUB_HANDLE, "url": GITHUB_URL,
			"tint": JuicePalette.CYAN, "toast": "OPENING GITHUB",
			"tip": "all the projects"},
		{"icon": "icon_instagram", "label": INSTAGRAM_HANDLE, "url": INSTAGRAM_URL,
			"tint": JuicePalette.GOLD, "toast": "OPENING INSTAGRAM",
			"tip": "tutorials and reels about game feel"},
	]

	var right := 1280.0 - 26.0
	for link in links:
		right -= _build_link(link, right) + 30.0


func _build_link(link: Dictionary, right_edge: float) -> float:
	const ICON_SIZE := 26.0
	const GAP := 12.0
	var font := JuicePalette.font()
	var label_width := font.get_string_size(link["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var width := ICON_SIZE + GAP + label_width

	var row := Control.new()
	row.name = str(link["icon"])
	row.size = Vector2(width, 40.0)
	row.position = Vector2(right_edge - width, 720.0 - 40.0 - 30.0)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(row)
	JuiceTween.center_pivot(row)

	var icon := TextureRect.new()
	icon.texture = load("res://Game/Assets/textures/%s.png" % link["icon"])
	# expand_mode before size: a TextureRect's minimum size is its texture size,
	# and Control.size is clamped to the minimum.
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.position = Vector2(0.0, 7.0)
	icon.modulate = link["tint"]
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var handle := Label.new()
	handle.text = link["label"]
	handle.position = Vector2(ICON_SIZE + GAP, 8.0)
	handle.add_theme_font_override(&"font", font)
	handle.add_theme_font_size_override(&"font_size", 17)
	handle.add_theme_color_override(&"font_color", JuicePalette.CREAM)
	handle.add_theme_constant_override(&"shadow_offset_x", 3)
	handle.add_theme_constant_override(&"shadow_offset_y", 3)
	handle.add_theme_color_override(&"font_shadow_color", JuicePalette.INK)
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(handle)

	row.mouse_entered.connect(func() -> void:
		Juice.punch(row, 0.12, 0.35)
		Juice.play_sfx(&"click", null, -14.0)
		_tooltip.show_for(str(link["tip"]), Rect2(row.position, row.size)))

	row.mouse_exited.connect(func() -> void: _tooltip.hide_tip())

	row.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var button := event as InputEventMouseButton
			if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
				_open_link(row, link))

	return width


func _open_link(row: Control, link: Dictionary) -> void:
	Juice.punch(row, 0.3, 0.4)
	Juice.play_sfx(&"confirm", null, -4.0)
	Juice.toast(str(link["toast"]), link["tint"], 1.4)
	OS.shell_open(str(link["url"]))


func _on_menu_activated(id: StringName, _index: int) -> void:
	match id:
		&"Strike": _strike()
		&"Collect": _collect()
		&"Glitch": _glitch()
		&"Overload": _overload()
		&"Screen": _cycle_look()
		&"Style": _cycle_style()
		&"Order": _cycle_order()


func _strike() -> void:
	_combo_count += 1
	_combo_timer = 2.5
	_combo.set_value(_combo_count)

	var damage := randi_range(40, 180) * _combo_count
	var crit := randf() < 0.22
	if crit:
		damage *= 3

	_score.set_value(_score.value + damage)
	_health.set_value(_health.value - randf_range(0.07, 0.14))
	_energy.set_value(_energy.value - 0.05)

	var at := Vector2(randf_range(760, 1140), randf_range(250, 420))
	Juice.damage_number(at, damage, crit)
	Juice.impact(at, 0.75 if crit else 0.45)

	if crit:
		Juice.toast("CRITICAL", JuicePalette.GOLD, 1.0)

	if _health.value <= 0.001:
		Juice.toast("DOWN", JuicePalette.RED, 2.0)
		Juice.slowmo(0.25, 0.4)
		Juice.vignette(0.6, 0.9)
	elif _health.value < 0.3:
		Juice.vignette(0.35, 0.5)


func _collect() -> void:
	_score.set_value(_score.value + 2500)
	_energy.set_value(_energy.value + 0.22)

	Juice.play_sfx(&"pickup")
	Juice.shake(0.2)
	Juice.flash(Color(0.43, 0.9, 0.63, 0.14), 0.18)
	Juice.toast("+2,500", JuicePalette.MINT, 1.2)


func _glitch() -> void:
	Juice.glitch(1.0, 0.4)
	Juice.play_sfx(&"error")
	Juice.toast("SIGNAL LOST", JuicePalette.RED, 1.6)

	var previous := _look_index
	Juice.set_look(ScreenFX.Look.BROKEN, 0.08)
	await get_tree().create_timer(0.55).timeout
	if is_inside_tree():
		Juice.set_look(SCREEN_LOOKS[previous], 0.5)


func _overload() -> void:
	Juice.slowmo(0.2, 0.5)
	Juice.hitstop(0.12)
	Juice.shake(0.8)
	Juice.zoom_punch(0.08, 0.5)
	Juice.flash(Color(1, 0.92, 0.6, 0.35), 0.25)
	Juice.chromatic(0.014, 0.5)

	Juice.vignette(0.5, 0.7)
	Juice.play_sfx(&"explode")

	_health.set_value(1.0)
	_energy.set_value(1.0)
	_score.set_value(_score.value + 10000)
	Juice.toast("OVERLOAD", JuicePalette.GOLD, 2.0)


func _cycle_look() -> void:
	_look_index = (_look_index + 1) % SCREEN_LOOKS.size()
	Juice.set_look(SCREEN_LOOKS[_look_index], 0.4)

	var button := _menu.get_button(4)
	if button != null:
		button.text = "SCREEN: %s" % LOOK_NAMES[_look_index]
	Juice.toast("SCREEN: %s" % LOOK_NAMES[_look_index], JuicePalette.PINK, 1.2)


func _cycle_style() -> void:
	_style_index = (_style_index + 1) % STYLE_NAMES.size()
	_refresh_transition_labels()
	Juice.play_sfx(&"confirm", null, -6.0)
	Juice.toast("STYLE: %s" % STYLE_NAMES[_style_index], JuicePalette.CYAN, 1.2)
	_replay_menu(5)


func _cycle_order() -> void:
	_order_index = (_order_index + 1) % ORDER_NAMES.size()
	_refresh_transition_labels()
	Juice.play_sfx(&"confirm", null, -6.0)
	Juice.toast("ORDER: %s" % ORDER_NAMES[_order_index], JuicePalette.CYAN, 1.2)
	_replay_menu(6)


func _replay_menu(focus_row: int) -> void:
	_menu.preview(_style_index, _order_index)
	_menu.select(focus_row)


func _refresh_transition_labels() -> void:
	var style_button := _menu.get_button(5)
	if style_button != null:
		style_button.text = "STYLE: %s" % STYLE_NAMES[_style_index]
	var order_button := _menu.get_button(6)
	if order_button != null:
		order_button.text = "ORDER: %s" % ORDER_NAMES[_order_index]


func _toggle_juice() -> void:
	Juice.enabled = not Juice.enabled
	_refresh_status()
	if Juice.enabled:
		Juice.toast("JUICE ON", JuicePalette.MINT, 1.2)


func _refresh_status() -> void:
	if _status == null:
		return
	if Juice.enabled:
		_status.text = "JUICE: ON"
		_status.add_theme_color_override(&"font_color", JuicePalette.MINT)
	else:
		_status.text = "JUICE: OFF   (same logic, no feel)"
		_status.add_theme_color_override(&"font_color", JuicePalette.RED)


func _reset() -> void:
	_combo_count = 0
	_score.set_value(0, true)
	_combo.set_value(0, true)
	_health.set_value(1.0, true)
	_energy.set_value(1.0, true)
	_menu.play_intro()
	Juice.toast("RESET", JuicePalette.CYAN, 1.0)
